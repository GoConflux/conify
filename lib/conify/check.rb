require 'mechanize'
require 'socket'
require 'timeout'
require 'uri'
require 'colored'
require 'conify/http'
require 'conify/manifest'
require 'conify/helpers'
require 'conify/okjson'
require 'conify/sso'

# Most all this code taken from https://github.com/heroku/kensa/blob/master/lib/heroku/kensa/check.rb

module Conify
  class Check
    attr_accessor :data
    include Conify::Helpers

    class CheckError < StandardError; end

    def initialize(data)
      @data = data
    end

    def env
      @data.fetch(:env, 'test')
    end

    def test(msg)
      display msg
    end

    def check(msg, &block)
      raise "The following check failed: #{msg}" unless block.call
    end

    def run(klass, data)
      klass.new(data).call
    end

    def warning(msg)
      display msg
    end

    def call
      call!
      true
    rescue CheckError => boom
      false
    end

    def to_proc
      me = self
      Proc.new { me.call! }
    end

    def url
      if data['api'][env].is_a? Hash
        base = data['api'][env]['base_url']
        uri = URI.parse(base)
        uri.query = nil
        uri.path = ''
        uri.to_s
      else
        data['api'][env].chomp("/")
      end
    end

    def api_requires?(feature)
      data["api"].fetch("requires", []).include?(feature)
    end
  end


  class ManifestCheck < Check

    ValidPriceUnits = %w[month dyno_hour]

    def call!
      check "if exists" do
        data.has_key?("id")
      end
      check "is a string" do
        data["id"].is_a?(String)
      end
      check "is not blank" do
        !data["id"].empty?
      end
      check "if exists" do
        data.has_key?("api")
      end
      check "is a hash" do
        data["api"].is_a?(Hash)
      end
      check "has a list of regions" do
        data["api"].has_key?("regions") &&
          data["api"]["regions"].is_a?(Array)
      end
      check "contains at least the US region" do
        data["api"]["regions"].include?("us") ||
          data["api"]["regions"].include?("*")
      end
      check "contains only valid region names" do
        data["api"]["regions"].all? { |reg| Manifest::REGIONS.include? reg }
      end
      check "contains password" do
        data["api"].has_key?("password") && data["api"]["password"] != ""
      end
      check "contains test url" do
        data["api"].has_key?("test")
      end
      check "contains production url" do
        data["api"].has_key?("production")
      end

      if data['api']['production'].is_a? Hash
        check "production url uses SSL" do
          data['api']['production']['base_url'] =~ /^https:/
        end
        check "sso url uses SSL" do
          data['api']['production']['sso_url'] =~ /^https:/
        end
      else
        check "production url uses SSL" do
          data['api']['production'] =~ /^https:/
        end
      end

      if data["api"].has_key?("config_vars")
        check "contains config_vars array" do
          data["api"]["config_vars"].is_a?(Array)
        end
        check "all config vars are hashes" do
          data["api"]["config_vars"].each do |c|
            error "Config #{c} is not a hash..." unless c.is_a?(Hash)
          end
        end
        check "all config vars are uppercase strings" do
          data["api"]["config_vars"].collect{ |c| c["name"] }.each do |k|
            if k =~ /^[A-Z][0-9A-Z_]+$/
              true
            else
              error "#{k.inspect} is not a valid ENV key"
            end
          end
        end
        check "all config vars are prefixed with the addon id" do
          data["api"]["config_vars"].collect{ |c| c["name"] }.each do |k|
            prefix = data["api"]["config_vars_prefix"] || data['id'].upcase.gsub('-', '_')
            if k =~ /^#{prefix}_/
              true
            else
              error "#{k} is not a valid ENV key - must be prefixed with #{prefix}_"
            end
          end
        end
      end

    end
  end


  class ProvisionResponseCheck < Check
    def call!
      response = data[:provision_response]

      check "contains an id" do
        response.is_a?(Hash) && response["id"]
      end

      check "id does not contain conflux_id" do
        if response["id"].to_s.include? data["conflux_id"].scan(/app(\d+)@/).flatten.first
          error "id cannot include conflux_id"
        else
          true
        end
      end

      if response.has_key?("configs")

        check "is an array" do
          response["configs"].is_a?(Array)
        end

        check "all config keys were previously defined in the manifest" do
          response_config_keys = response["configs"].collect { |c| c["name"] }
          manifest_config_keys = data["api"]["config_vars"].collect { |c| c["name"] }
          diff = response_config_keys - manifest_config_keys

          if !diff.empty?
            error "The following keys are not in the manifest: #{diff.join(', ')}"
          end

          true
        end

        check "all keys in the manifest are present" do
          response_config_keys = response["configs"].collect { |c| c["name"] }
          manifest_config_keys = data["api"]["config_vars"].collect { |c| c["name"] }
          diff = manifest_config_keys - response_config_keys

          if !diff.empty?
            error "The following keys that exist in the manifest were not returned: #{diff.join(', ')}"
          end

          true
        end

        check "all configs are hashes with String 'name' and 'value' keys" do
          response["configs"].each do |c|
            error "Config #{c} is not a hash..." unless c.is_a?(Hash)
            error "Config #{c} does not contain the 'name' key" unless c.key?("name")
            error "The 'name' key #{c["name"]} is not a string..." unless c["name"].is_a?(String)
            error "Config #{c} does not contain the 'value' key" unless c.key?("value")
            error "The 'name' key #{c["value"]} is not a string..." unless c["value"].is_a?(String)
            true
          end
        end

        check "URL configs vars" do
          response["configs"].each do |c|
            next unless c["name"] =~ /_URL$/
            begin
              value = c["value"]
              uri = URI.parse(value)
              error "#{value} is not a valid URI - missing host" unless uri.host
              error "#{value} is not a valid URI - missing scheme" unless uri.scheme
              error "#{value} is not a valid URI - pointing to localhost" if env == 'production' && uri.host == 'localhost'
            rescue URI::Error
              error "#{value} is not a valid URI"
            end
          end
        end

        check "log_drain_url is returned if required" do
          return true unless api_requires?("syslog_drain")

          drain_url = response['log_drain_url']

          if !drain_url || drain_url.empty?
            error "must return a log_drain_url"
          else
            true
          end

          unless drain_url =~ /\A(https|syslog):\/\/[\S]+\Z/
            error "must return a syslog_drain_url like syslog://log.example.com:9999"
          else
            true
          end
        end

      end
    end

  end

  class ApiCheck < Check
    def base_path
      if data['api'][env].is_a? Hash
        URI.parse(data['api'][env]['base_url']).path
      else
        '/conflux/resources'
      end
    end

    def conflux_id
      "app#{rand(10000)}@kensa.conflux.com"
    end

    def credentials
      [ data['id'], data['api']['password'] ]
    end

    def callback
      "http://localhost:7779/callback/999"
    end

    def create_provision_payload
      payload = {
        :conflux_id => conflux_id,
        :plan => data[:plan] || 'test',
        :callback_url => callback,
        :logplex_token => nil,
        :region => "amazon-web-services::us-east-1",
        :options => data[:options] || {},
        :uuid => SecureRandom.uuid
      }

      if api_requires?("syslog_drain")
        payload[:log_drain_token] = SecureRandom.hex
      end
      payload
    end
  end

  class DuplicateProvisionCheck < ApiCheck
    include HTTPForChecks

    READLEN = 1024 * 10

    def call!
      json = nil
      response = nil
      code = nil

      payload = create_provision_payload

      code1, json1 = post(credentials, base_path, payload)

      payload[:uuid] = SecureRandom.uuid
      code2, json2 = post(credentials, base_path, payload)

      json1 = OkJson.decode(json1)
      json2 = OkJson.decode(json2)

      if api_requires?("many_per_app")
        check "returns different ids" do
          if json1["id"] == json2["id"]
            error "multiple provisions cannot return the same id"
          else
            true
          end
        end
      end
    end
  end

  class ProvisionCheck < ApiCheck
    include HTTPForChecks

    READLEN = 1024 * 10

    def call!
      response = nil
      code = nil
      json = nil

      payload = create_provision_payload

      test "POST #{base_path}"
      check "response" do
        payload[:uuid] = SecureRandom.uuid
        code, json = post(credentials, base_path, payload)

        if code == 200
          # noop
        elsif code == -1
          error("unable to connect to #{url}")
        else
          error("expected 200, got #{code}")
        end

        true
      end

      check "valid JSON" do
        begin
          response = OkJson.decode(json)
        rescue OkJson::Error => boom
          error boom.message
        rescue NoMethodError => boom
          error "error parsing JSON"
        end
        true
      end

      check "authentication" do
        wrong_credentials = ['wrong', 'secret']
        payload[:uuid] = SecureRandom.uuid
        code, _ = post(wrong_credentials, base_path, payload)
        error("expected 401, got #{code}") if code != 401
        true
      end

      data[:provision_response] = response

      run ProvisionResponseCheck, data.merge("conflux_id" => conflux_id)

      if !api_requires?("many_per_app")
        run DuplicateProvisionCheck, data
      end
    end
  end


  class DeprovisionCheck < ApiCheck
    include HTTPForChecks

    def call!
      id = data[:id]
      raise ArgumentError, "No id specified" if id.nil?

      path = "#{base_path}/#{CGI::escape(id.to_s)}"

      test "DELETE #{path}"
      check "response" do
        code, _ = delete(credentials, path, nil)
        if code == 200
          true
        elsif code == -1
          error("unable to connect to #{url}")
        else
          error("expected 200, got #{code}")
        end
      end

      check "authentication" do
        wrong_credentials = ['wrong', 'secret']
        code, _ = delete(wrong_credentials, path, nil)
        error("expected 401, got #{code}") if code != 401
        true
      end

    end

  end


  class PlanChangeCheck < ApiCheck
    include HTTPForChecks

    def call!
      id = data[:id]
      raise ArgumentError, "No id specified" if id.nil?

      new_plan = data[:plan]
      raise ArgumentError, "No plan specified" if new_plan.nil?

      path = "#{base_path}/#{CGI::escape(id.to_s)}"
      payload = {:plan => new_plan, :conflux_id => conflux_id}

      test "PUT #{path}"
      check "response" do
        payload[:uuid] = SecureRandom.uuid
        code, _ = put(credentials, path, payload)
        if code == 200
          true
        elsif code == -1
          error("unable to connect to #{url}")
        else
          error("expected 200, got #{code}")
        end
      end

      check "authentication" do
        wrong_credentials = ['wrong', 'secret']
        payload[:uuid] = SecureRandom.uuid
        code, _ = put(wrong_credentials, path, payload)
        error("expected 401, got #{code}") if code != 401
        true
      end
    end
  end


  class SsoCheck < ApiCheck
    include HTTPForChecks

    def agent
      @agent ||= Mechanize.new
    end

    def mechanize_get
      if @sso.POST?
        page = agent.post(@sso.post_url, @sso.query_params)
      else
        page = agent.get(@sso.get_url)
      end
      return page, 200
    rescue Mechanize::ResponseCodeError => error
      return nil, error.response_code.to_i
    rescue Errno::ECONNREFUSED
      error("connection refused to #{url}")
    end

    def check(msg)
      @sso = Sso.new(data)
      super
    end

    def call!
      error "Need an sso salt to perform sso test" unless data['api']['sso_salt']

      sso = Sso.new(data)
      verb = sso.POST? ? 'POST' : 'GET'
      test "#{verb} #{sso.path}"

      check "validates token" do
        @sso.token = 'invalid'
        page, respcode = mechanize_get
        error("expected 403, got #{respcode}") unless respcode == 403
        true
      end

      check "validates timestamp" do
        @sso.timestamp = (Time.now - 60*6).to_i
        page, respcode = mechanize_get
        error("expected 403, got #{respcode}") unless respcode == 403
        true
      end

      page_logged_in = nil
      check "logs in" do
        page_logged_in, respcode = mechanize_get
        error("expected 200, got #{respcode}") unless respcode == 200
        true
      end

    end
  end

  class AllCheck < Check

    def call!
      run ManifestCheck, data
      run ProvisionCheck, data

      response = data[:provision_response]
      data.merge!(id: response['id'])
      data[:plan] ||= 'foo'

      run PlanChangeCheck, data
      run DeprovisionCheck, data
      run SsoCheck, data
    end

    def run_in_env(env)
      env.each {|key, value| ENV[key] = value }
      yield
      env.keys.each {|key| ENV.delete(key) }
    end

  end

end
