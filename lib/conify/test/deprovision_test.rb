require 'conify/test/api_test'

class Conify::DeprovisionTest < Conify::ApiTest

  OUTPUT_COMPLETION = true

  def call!
    id = data[:id]
    raise ArgumentError, 'Deprovision Test: No id specified' if id.nil?
    path = "#{base_path}/#{CGI::escape(id.to_s)}"

    test 'response' do
      code, _ = delete(credentials, path, nil)
      if code == 200
        true
      elsif code == -1
        error "Deprovision Test: unable to connect to #{url}"
      else
        error "Deprovision Test: expected 200, got #{code}"
      end
    end

    test 'authentication' do
      code, _ = delete(invalid_creds, path, nil)
      error "Deprovision Test: expected 401, got #{code}" if code != 401
      true
    end
  end

end
