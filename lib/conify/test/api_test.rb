require 'conify/test'
require 'conify/http'
require 'uri'

class Conify::ApiTest < Conify::Test
  include Conify::HTTPForTests

  def base_path
    if data['api'][env].is_a?(Hash)
      URI.parse(data['api'][env]['base_url']).path
    else
      '/conflux/resources'
    end
  end

  def conflux_id
    "app#{rand(10000)}@conify.goconflux.com"
  end

  def credentials
    [ data['id'], data['api']['password'] ]
  end

  def invalid_creds
    ['wrong', 'secret']
  end

  def callback
    'http://localhost:7779/callback/999'
  end

  def create_provision_payload
    payload = {
      conflux_id: conflux_id,
      plan: 'test',
      callback_url: callback,
      logplex_token: nil,
      options: data[:options] || {},
      uuid: SecureRandom.uuid
    }

    payload[:log_drain_token] = SecureRandom.hex if api_requires?('syslog_drain')

    payload
  end

end