require 'securerandom'

module Conify
  module Manifest
    extend self

    def password_gen(size = 8)
      SecureRandom.hex(size)
    end

    def default_port
      3000
    end

    def template
      <<-JSON
{
  "id": "myservice",
  "api": {
    "config_vars": [
      {
        "name": "MYSERVICE_URL",
        "description": "Short config var description"
      }
    ],
    "password": "#{password_gen}",
    "sso_salt": "#{password_gen}",
    "production": {
      "base_url": "https://yourapp.com/conflux/resources",
      "sso_url": "https://yourapp.com/conflux/sso"
    },
    "test": {
      "base_url": "http://localhost:#{default_port}/conflux/resources",
      "sso_url": "http://localhost:#{default_port}/conflux/sso"
    }
  }
}
      JSON
    end

  end
end
