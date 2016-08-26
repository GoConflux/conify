require 'restclient'
require 'uri'

module Conify
  class Sso
    attr_accessor :uuid, :url, :proxy_port, :timestamp, :token

    def initialize(data)
      @uuid = data[:id]
      @salt = data['api']['sso_salt']
      env = data.fetch('env', 'test')

      if @url = data['api'][env]['sso_url']
        @use_post = true
        @proxy_port = find_available_port
      else
        @url = data['api'][env].chomp('/')
      end

      @timestamp  = Time.now.to_i
      @token = make_token(@timestamp)
    end

    def path
      self.POST? ? URI.parse(url).path : "/conflux/resources/#{uuid}"
    end

    def POST?
      @use_post
    end

    def sso_url
      self.POST? ? "http://localhost:#{@proxy_port}/" : full_url
    end

    def full_url
      [ url, path, querystring ].join
    end
    alias get_url full_url

    def post_url
      url
    end

    def timestamp=(other)
      @timestamp = other
      @token = make_token(@timestamp)
    end

    def make_token(t)
      Digest::SHA1.hexdigest([@uuid, @salt, t].join(':'))
    end

    def querystring
      return '' unless @salt
      '?' + query_data
    end

    def query_data
      query_params.map{|p| p.join('=')}.join('&')
    end

    def query_params
      {
        'token' => @token,
        'timestamp' => @timestamp.to_s,
        'nav-data' => sample_nav_data,
        'email' => 'username@example.com',
        'app' => 'myapp'
      }.tap do |params|
        params.merge!('uuid' => @uuid) if self.POST?
      end
    end

    def sample_nav_data
      json = OkJson.encode({
        'addon' => 'Your Addon',
        'appname' => 'myapp',
        'addons' => [
          { 'slug' => 'cron', 'name' => 'Cron' },
          { 'slug' => 'custom_domains+wildcard', 'name' => 'Custom Domains + Wildcard' },
          { 'slug' => 'youraddon', 'name' => 'Your Addon', 'current' => true }
        ]
      })

      base64_url_variant(json)
    end

    def base64_url_variant(text)
      base64 = [text].pack('m').gsub('=', '').gsub("\n", '')
      base64.tr('+/','-_')
    end

    def message
      if self.POST?
        "POSTing #{query_data} to #{post_url} via proxy on port #{@proxy_port}"
      else
        "Opening #{full_url}"
      end
    end

    def find_available_port
      server = TCPServer.new('127.0.0.1', 0)
      server.addr[1]
    ensure
      server.close if server
    end

  end
end
