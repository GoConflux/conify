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

    end

    def deprovision

    end

    def change_plan

    end

    def sso

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
