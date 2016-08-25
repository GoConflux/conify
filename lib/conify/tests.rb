require 'conify/helpers'

module Conify
  module Tests
    extend self
    extend Conify::Helpers

    def perform(is_prod = false)
      @is_prod = is_prod

      begin
        provision
        deprovision
        change_plan
        sso

        display "Tests Passed!"
      rescue Exception => e
        display "Tests Failed with Error: #{e.message}"
      end
    end

    def provision
      # Make a test POST to base_url
    end

    def deprovision
      # Make a test DELETE to base_url
    end

    def change_plan
      # Make a test PUT to base_url
    end

    def sso
      # Make a test GET to sso_url
    end

    def base_url
      url_for_key('base_url')
    end

    def sso_url
      url_for_key('sso_url')
    end

    def url_for_key(key)
      scope = @is_prod ? 'production' : 'test'
      url = ((manifest['api'] || {})[scope] || {})[key]

      if url.empty?
        display "Manifest Key Missing: json[\"api\"][\"#{scope}\"][\"#{key}\"] needs to exist in order for tests to proceed."
        exit(0)
      else
        url
      end
    end

    def manifest
      @manifest ||= manifest_content
    end

  end
end
