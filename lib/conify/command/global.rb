require 'conify/command/abstract_command'
require 'conify/manifest'
require 'conify/test/all_test'
require 'conify/api/users'
require 'conify/api/services'

class Conify::Command::Global < Conify::Command::AbstractCommand

  def init
    # Error out if conflux-manifest.json already exists
    if File.exists?(manifest_path)
      error "File #{manifest_filename} already exists."
    else
      begin
        # Create new conflux-manifest.json file from template
        File.open(manifest_path, 'w+') do |f|
          f.write(Conify::Manifest.template)
        end

        display "Created new manifest at #{manifest_filename}"
      rescue Exception => e
        File.delete(manifest_path) # Remove file if something screws up during file creation
        display "Error initializing conify manifest: #{e0.message}"
      end
    end
  end

  def test
    begin
      # Get the content from conflux-manifest.json and add the 'env'
      # key specifying which environment to test
      data = manifest_content
      data['env'] = (@args[1] === '--production') ? 'production' : 'test'

      # Run all tests to ensure Conflux integration is set up correctly
      all_tests = Conify::AllTest.new(data)
      exit(1) if !all_tests.call

      display 'Everything checks out!'
    rescue Exception => e
      display e.message
    end
  end

  def submit
    # First ensure manifest exists
    if !File.exists?(manifest_path)
      error "No Conflux manifest exists yet.\nRun 'conflux init' to create a new manifest."
    end

    # Request Conflux email/password creds
    creds = ask_for_conflux_creds

    # Login to Conflux with these creds, returning a valid user-token
    auth_resp = Conify::Api::Users.new.login(creds)

    # Submit new service to Conflux
    Conify::Api::Services.new.submit(manifest_content, auth_resp['token'])

    display 'Submitted new service to Conflux!'
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

    module Submit
      DESCRIPTION = 'Submit your service to Conflux'
      VALID_ARGS = [ [] ]
    end

  end

end