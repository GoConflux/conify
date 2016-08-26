require 'conify/test/api_test'
require 'conify/test/provision_response_test'
require 'conify/test/duplicate_provision_test'
require 'conify/okjson'

class Conify::ProvisionTest < Conify::ApiTest

  OUTPUT_COMPLETION = true

  def call!
    response, code, json = nil
    payload = create_provision_payload

    test 'response' do
      payload[:uuid] = SecureRandom.uuid
      code, json = post(credentials, base_path, payload)

      if code == 200
        # noop
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
      payload[:uuid] = SecureRandom.uuid
      code, _ = post(invalid_creds, base_path, payload)
      error "Provision Test: expected 401, got #{code}" if code != 401
      true
    end

    data[:provision_response] = response

    run(Conify::ProvisionResponseTest, data.merge('conflux_id' => conflux_id))
    run(Conify::DuplicateProvisionTest, data) unless api_requires?('many_per_app')
  end

end
