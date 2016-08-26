require 'conify/test/api_test'
require 'conify/okjson'

class Conify::DuplicateProvisionTest < Conify::ApiTest

  def call!
    json, response, code = nil
    payload = create_provision_payload

    code1, json1 = post(credentials, base_path, payload)
    payload[:uuid] = SecureRandom.uuid

    code2, json2 = post(credentials, base_path, payload)

    json1 = OkJson.decode(json1)
    json2 = OkJson.decode(json2)

    if api_requires?('many_per_app')
      test 'returns different ids' do
        error 'multiple provisions cannot return the same id' if json1['id'] == json2['id']
        true
      end
    end
  end

end