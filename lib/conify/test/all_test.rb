require 'conify/test'
require 'conify/test/manifest_test'
require 'conify/test/provision_test'
require 'conify/test/plan_change_test'
require 'conify/test/deprovision_test'
require 'conify/test/sso_test'

class Conify::AllTest < Conify::Test

  def call!
    run(Conify::ManifestTest, data)
    run(Conify::ProvisionTest, data)

    response = data[:provision_response]
    data.merge!(id: response['id'])
    data[:plan] ||= 'foo'

    run(Conify::PlanChangeTest, data)
    run(Conify::SsoTest, data)
    run(Conify::DeprovisionTest, data)
  end

end