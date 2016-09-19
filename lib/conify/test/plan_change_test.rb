require 'conify/test/api_test'

class Conify::PlanChangeTest < Conify::ApiTest

  OUTPUT_COMPLETION = true

  def call
    external_uuid = data[:external_uuid]
    raise ArgumentError, 'Plan Change Test: No external_uuid specified' if external_uuid.nil?

    path = "#{base_path}/#{external_uuid.to_s}"
    payload = { plan: 'new_plan', conflux_id: data[:external_username] }

    test 'response' do
      code, _ = put(credentials, path, payload)

      if code == 200
        true
      elsif code == -1
        error "Plan Change Test: unable to connect to #{url}"
      else
        error "Plan Change Test: expected 200, got #{code}"
      end
    end

    test 'authentication' do
      code, _ = put(invalid_creds, path, payload)
      error "Plan Change Test: expected 401, got #{code}" if code != 401
      true
    end
  end

end
