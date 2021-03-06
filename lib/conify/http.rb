require 'restclient'
require 'conify/okjson'

# Used for making http requests when testing Conflux compatibility
module Conify
  module HTTPForTests

    def get(path, params={})
      path = "#{path}?" + params.map { |k, v| "#{k}=#{v}" }.join('&') unless params.empty?
      request(:get, [], path)
    end

    def post(credentials, path, payload=nil)
      request(:post, credentials, path, payload)
    end

    def put(credentials, path, payload=nil)
      request(:put, credentials, path, payload)
    end

    def delete(credentials, path, payload=nil)
      request(:delete, credentials, path, payload)
    end

    def request(method, credentials, path, payload=nil)
      code = nil
      body = nil

      begin
        args = [{ accept: 'application/json' }]

        if payload
          args.first[:content_type] = 'application/json'
          args.unshift(payload.to_json)
        end

        user, pass = credentials
        body = RestClient::Resource.new(url, user: user, password: pass, verify_ssl: false)[path].send(
          method,
          *args
        ).to_s

        code = 200
      rescue RestClient::ExceptionWithResponse => e
        code = e.http_code
        body = e.http_body
      rescue Errno::ECONNREFUSED
        code = -1
        body = nil
      end

      [code, body]
    end

  end
end
