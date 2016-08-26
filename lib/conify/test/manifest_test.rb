require 'conify/test'
require 'conify/manifest'

class Conify::ManifestTest < Conify::Test

  OUTPUT_COMPLETION = true

  def call!
    test 'id key exists' do
      data.has_key?('id')
    end

    test 'id is a string' do
      data['id'].is_a?(String)
    end

    test 'id is not blank' do
      !data['id'].empty?
    end

    test 'api key exists' do
      data.has_key?('api')
    end

    test 'api is a hash' do
      data['api'].is_a?(Hash)
    end

    test 'api has a list of regions' do
      data['api'].has_key?('regions') && data['api']['regions'].is_a?(Array)
    end

    test 'api contains at least the US region' do
      data['api']['regions'].include?('us') || data['api']['regions'].include?('*')
    end

    test 'api contains only valid region names' do
      data['api']['regions'].all? { |reg| Conify::Manifest::REGIONS.include? reg }
    end

    test 'api contains password' do
      data['api'].has_key?('password') && data['api']['password'] != ''
    end

    test 'api contains test url' do
      data['api'].has_key?('test')
    end

    test 'api contains production url' do
      data['api'].has_key?('production')
    end

    if data['api']['production'].is_a?(Hash)
      test 'production url uses SSL' do
        data['api']['production']['base_url'] =~ /^https:/
      end

      test 'sso url uses SSL' do
        data['api']['production']['sso_url'] =~ /^https:/
      end
    else
      test 'production url uses SSL' do
        data['api']['production'] =~ /^https:/
      end
    end

    if data['api'].has_key?('config_vars')
      test 'contains config_vars array' do
        data['api']['config_vars'].is_a?(Array)
      end

      test 'all config vars are hashes' do
        data['api']['config_vars'].each do |c|
          error "Config #{c} is not a hash..." unless c.is_a?(Hash)
        end
      end

      test 'all config vars are uppercase strings' do
        data['api']['config_vars'].collect{ |c| c['name'] }.each do |k|
          if k =~ /^[A-Z][0-9A-Z_]+$/
            true
          else
            error "#{k.inspect} is not a valid ENV key"
          end
        end
      end

      test 'all config vars are prefixed with the addon id' do
        data['api']['config_vars'].collect{ |c| c['name'] }.each do |k|
          prefix = data['api']['config_vars_prefix'] || data['id'].upcase.gsub('-', '_')
          if k =~ /^#{prefix}_/
            true
          else
            error "#{k} is not a valid ENV key - must be prefixed with #{prefix}_"
          end
        end
      end
    end
  end

end
