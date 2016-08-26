require 'conify/test/api_test'

class Conify::PlanChangeTest < Conify::ApiTest

  OUTPUT_COMPLETION = true

  def call!
    id = data[:id]
    new_plan = data[:plan]

    raise ArgumentError, 'Plan Change Test: No id specified' if id.nil?
    raise ArgumentError, 'Plan Change Test: No plan specified' if new_plan.nil?

    path = "#{base_path}/#{CGI::escape(id.to_s)}"
    payload = { plan: new_plan, conflux_id: conflux_id }

    test 'response' do
      payload[:uuid] = SecureRandom.uuid
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
      payload[:uuid] = SecureRandom.uuid
      code, _ = put(invalid_creds, path, payload)
      error "Plan Change Test: expected 401, got #{code}" if code != 401
      true
    end
  end

end
