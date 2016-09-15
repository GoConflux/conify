require 'conify/command/abstract_command'
require 'conify/manifest'
require 'conify/test/all_test'
require 'conify/test/manifest_test'
require 'conify/api/users'
require 'conify/api/addons'

class Conify::Command::Global < Conify::Command::AbstractCommand

  def init
    # Error out if conflux-manifest.json already exists
    if File.exists?(manifest_path)
      error "Manifest File #{manifest_filename} already exists."
    else
      begin
        # Create new conflux-manifest.json file from template
        File.open(manifest_path, 'w+') do |f|
          f.write(Conify::Manifest.template)
        end

        display([
          "Created new manifest template at #{manifest_filename}.",
          "Modify it to your service's specs and then run 'conify test'."
        ].join("\n"))
      rescue Exception => e
        File.delete(manifest_path) # Remove file if something screws up during file creation
        display "Error initializing conify manifest: #{e.message}"
      end
    end
  end

  def test
    begin
      # Get the content from conflux-manifest.json and add the 'env'
      # key specifying which environment to test.
      data = manifest_content
      data['env'] = (@args[0] === '--production') ? 'production' : 'test'

      # Run all tests to ensure Conflux integration is set up correctly
      all_tests_valid = Conify::AllTest.new(data).call
      exit(1) unless all_tests_valid

      display 'Everything checks out!'
    rescue Exception => e
      display e.message
    end
  end

  def push
    # First ensure manifest exists.
    if !File.exists?(manifest_path)
      error "No Conflux manifest exists yet.\nRun 'conflux init' to create a new manifest."
    end

    # Run Manifest Test to ensure file is valid.
    manifest_valid = Conify::ManifestTest.new(manifest_content).call
    exit(1) unless manifest_valid

    # Request Conflux email/password creds.
    creds = ask_for_conflux_creds

    # Login to Conflux with these creds, returning a valid user-token.
    auth_resp = Conify::Api::Users.new.login(creds)

    # Push new service to Conflux.
    push_resp = Conify::Api::Addons.new.push(manifest_content, auth_resp['user_token'])

    display "Successfully pushed draft service to Conflux!\nRun 'conify open' to finish editing your service's information."
  end

  def open
    # First ensure manifest exists.
    if !File.exists?(manifest_path)
      error "No Conflux manifest exists yet.\nRun 'conflux init' to create a new manifest."
    end

    service_id = manifest_content['id'] || ''
    error 'Manifest must have an "id" field.' if service_id.empty?

    edit_service_url = "#{site_url}/services/#{service_id}/edit"
    display "Opening Conflux Service at: #{edit_service_url}"
    open_url(edit_service_url)
  end

  #----------------------------------------------------------------------------

  module CommandInfo

    module Init
      DESCRIPTION = 'Create a new Conflux manifest'
      VALID_ARGS = [ [] ]
    end

    module Test
      DESCRIPTION = 'Test that your Conflux integration is set up correctly'
      VALID_ARGS = [ [], ['--production'] ]
    end

    module Push
      DESCRIPTION = 'Push your draft service to Conflux'
      VALID_ARGS = [ [] ]
    end

    module Open
      DESCRIPTION = 'Open the url to edit your service on Conflux'
      VALID_ARGS = [ [] ]
    end

  end

end