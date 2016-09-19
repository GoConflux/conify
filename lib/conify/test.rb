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
      @data.fetch('env', 'test')
    end

    def test(msg, &block)
      raise "Failed: #{msg}" unless block.call
    end

    def run(klass, data)
      test_name = klass.to_s.gsub('Conify::', '').split(/(?=[A-Z])/).join(' ')

      begin
        klass.new(data).call
      rescue Exception => e
        error "#{test_name} #{e.message}"
      end

      if klass.const_defined?('OUTPUT_COMPLETION') && klass.const_get('OUTPUT_COMPLETION')
        display "#{test_name}: Looks good..."
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
