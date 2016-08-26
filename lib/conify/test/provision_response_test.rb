require 'conify/test'

class Conify::ProvisionResponseTest < Conify::Test

  def call!
    response = data[:provision_response]

    test 'contains an id' do
      response.is_a?(Hash) && response['id']
    end

    test 'id does not contain conflux_id' do
      if response['id'].to_s.include? data['conflux_id'].scan(/app(\d+)@/).flatten.first
        error 'id cannot include conflux_id'
      else
        true
      end
    end

    if response.has_key?('configs')
      test 'is an array' do
        response['configs'].is_a?(Array)
      end

      test 'all config keys were previously defined in the manifest' do
        response_config_keys = response['configs'].collect { |c| c['name'] }
        manifest_config_keys = data['api']['config_vars'].collect { |c| c['name'] }
        diff = response_config_keys - manifest_config_keys
        error "The following keys are not in the manifest: #{diff.join(', ')}" if !diff.empty?
        true
      end

      test 'all keys in the manifest are present' do
        response_config_keys = response['configs'].collect { |c| c['name'] }
        manifest_config_keys = data['api']['config_vars'].collect { |c| c['name'] }
        diff = manifest_config_keys - response_config_keys

        if !diff.empty?
          error "The following keys that exist in the manifest were not returned: #{diff.join(', ')}"
        end

        true
      end

      test 'all configs are hashes with String \'name\' and \'value\' keys' do
        response['configs'].each do |c|
          error "Config #{c} is not a hash..." unless c.is_a?(Hash)
          error "Config #{c} does not contain the 'name' key" unless c.key?('name')
          error "The 'name' key #{c["name"]} is not a string..." unless c['name'].is_a?(String)
          error "Config #{c} does not contain the 'value' key" unless c.key?('value')
          error "The 'name' key #{c["value"]} is not a string..." unless c['value'].is_a?(String)
          true
        end
      end

      test 'URL configs vars' do
        response['configs'].each do |c|
          next unless c['name'] =~ /_URL$/

          begin
            value = c['value']
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
