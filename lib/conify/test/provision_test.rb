require 'conify/test/api_test'
require 'conify/test/provision_response_test'
require 'conify/okjson'

class Conify::ProvisionTest < Conify::ApiTest

  OUTPUT_COMPLETION = true

  def call
    response, code, json = nil
    payload = create_provision_payload

    data[:external_username] = payload[:conflux_id] # store for later

    test 'response' do
      code, json = post(credentials, base_path, payload)

      if code == 200
        # Good shit
      elsif code == -1
        error "Provision Test: unable to connect to #{url}"
      else
        error "Provision Test: expected 200, got #{code}"
      end

      true
    end

    test 'valid JSON' do
      begin
        response = OkJson.decode(json)
      rescue OkJson::Error => e
        error e.message
      rescue NoMethodError => e
        error 'Provision Test: error parsing JSON'
      end

      true
    end

    test 'authentication' do
      code, _ = post(invalid_creds, base_path, payload)
      error "Provision Test: expected 401, got #{code}" if code != 401
      true
    end

    data[:provision_response] = response

    run(Conify::ProvisionResponseTest, data)
  end

end
