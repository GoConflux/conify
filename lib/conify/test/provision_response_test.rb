require 'conify/test'
require 'uri'

class Conify::ProvisionResponseTest < Conify::Test

  def call
    response = data[:provision_response]

    test 'contains an id' do
      response.is_a?(Hash) && response['id']
    end

    test 'id does not contain conflux_id' do
      if response['id'].to_s.include? data[:external_username].scan(/app(\d+)@/).flatten.first
        error 'id cannot include conflux_id'
      else
        true
      end
    end

    if response.has_key?('config')
      test 'is a hash' do
        response['config'].is_a?(Hash)
      end

      test 'all config keys were previously defined in the manifest' do
        response['config'].keys.each do |key|
          error "#{key} is not in the manifest" unless data['api']['config_vars'].include?(key)
        end
        true
      end

      test 'all keys in the manifest are present' do
        difference = data['api']['config_vars'] - response['config'].keys
        unless difference.empty?
          verb = (difference.size == 1) ? 'is' : 'are'
          error "Config(s) #{difference.join(', ')} #{verb} missing from the provision response"
        end
        true
      end

      test 'all config values are strings' do
        response['config'].each do |k, v|
          if v.is_a?(String)
            true
          else
            error "the key #{k} doesn't contain a string (#{v.inspect})"
          end
        end
      end

      test 'URL configs vars' do
        response['config'].each do |key, value|
          next unless key =~ /_URL$/
          begin
            uri = URI.parse(value)
            error "#{value} is not a valid URI - missing host" unless uri.host
            error "#{value} is not a valid URI - missing scheme" unless uri.scheme
            error "#{value} is not a valid URI - pointing to localhost" if env == 'production' && uri.host == 'localhost'
          rescue URI::Error
            error "#{value} is not a valid URI"
          end
        end
      end

      test 'log_drain_url is returned if required' do
        if !api_requires?('syslog_drain')
          true
        else
          drain_url = response['log_drain_url']

          if !drain_url || drain_url.empty?
            error 'must return a log_drain_url'
          else
            true
          end

          unless drain_url =~ /\A(https|syslog):\/\/[\S]+\Z/
            error 'must return a syslog_drain_url like syslog://log.example.com:9999'
          else
            true
          end
        end
      end

    end
  end

end
