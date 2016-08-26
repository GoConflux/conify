require 'conify/helpers'
require 'uri'

module Conify
  class Test
    attr_accessor :data
    include Conify::Helpers

    def initialize(data)
      @data = data
    end

    def env
      @data.fetch(:env, 'test')
    end

    def test(msg, &block)
      raise "Test failed: #{msg}" unless block.call
    end

    def run(klass, data)
      klass.new(data).call

      if klass.const_get('OUTPUT_COMPLETION')
        test_name = klass.to_s.gsub('Conify::', '').split(/(?=[A-Z])/).join(' ')
        display "#{test_name}: Looks good..."
      end
    end

    def call
      begin
        call!
        true
      rescue
        false
      end
    end

    def url
      if data['api'][env].is_a? Hash
        base = data['api'][env]['base_url']
        uri = URI.parse(base)
        uri.query = nil
        uri.path = ''
        uri.to_s
      else
        data['api'][env].chomp('/')
      end
    end

    def api_requires?(feature)
      data['api'].fetch('requires', []).include?(feature)
    end
  end

end
