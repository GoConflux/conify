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

    # data[:provision_response] has already been set from the above test,
    # so add 'external_uuid' returned from inside this hash to the data object.
    data[:external_uuid] = data[:provision_response]['id']

    run(Conify::PlanChangeTest, data)
    run(Conify::SsoTest, data)
    run(Conify::DeprovisionTest, data)
  end

end