require 'securerandom'
require 'conify/helpers'

module Conify
  module Manifest
    extend self
    extend Conify::Helpers

    def password_gen(size = 8)
      SecureRandom.hex(size)
    end

    def default_port
      3000
    end

    def template
      # Use conflux template as default
      manifest = JSON.parse(conflux_template)

      # If the kensa manifest exists, return the exclusively merged two manifests.
      if File.exists?(kensa_manifest_name)
        kensa_manifest = JSON.parse(File.read(kensa_manifest_path)) rescue {}
        manifest = exclusive_deep_merge(manifest, kensa_manifest)
      end

      # Don't copy over password or sso_salt, so just set them now:
      manifest['api']['password'] = password_gen
      manifest['api']['sso_salt'] = password_gen

      JSON.pretty_generate(manifest)
    end

    def conflux_template
      <<-JSON
{
  "id": "myservice",
  "api": {
    "config_vars": ["MYSERVICE_URL"],
    "password": "",
    "sso_salt": "",
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
