require 'securerandom'

module Conify
  module Manifest
    extend self

    def password_gen(size = 8)
      SecureRandom.hex(size)
    end

    def port
      3000
    end

    def template
      <<-JSON
{
  "id": "myservice",
  "api": {
    "config_vars": [ "MYSERVICE_URL" ],
    "password": "#{password_gen}",
    "sso_salt": "#{password_gen}",
    "regions": ["us"],
    "production": {
      "base_url": "https://yourapp.com/conflux/resources",
      "sso_url": "https://yourapp.com/sso/login"
    },
    "test": {
      "base_url": "http://localhost:#{port}/conflux/resources",
      "sso_url": "http://localhost:#{port}/sso/login"
    }
  }
}
      JSON
    end

  end
end