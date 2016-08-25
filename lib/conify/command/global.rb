require 'conify/command/abstract_command'
require 'conify/manifest'
require 'conify/check'
require 'conify/api/users'
require 'conify/api/services'

class Conify::Command::Global < Conify::Command::AbstractCommand

  def init
    if File.exists?(manifest_path)
      error "File #{manifest_filename} already exists."
    else
      begin
        File.open(manifest_path, 'w+') do |f|
          f.write(Conify::Manifest.template)
        end

        display "Created new manifest at #{manifest_filename}"
      rescue Exception => e
        File.delete(manifest_path)
        display "Error initializing conify manifest: #{e.message}"
      end
    end
  end

  def test
    begin
      data = manifest_content
      data['env'] = (@args[1] === '--production') ? 'production' : 'test'
      check = Conify::AllCheck.new(data)
      result = check.call
      exit(1) if !result && !(@options[:test])
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
      DESCRIPTION = 'Create a new manifest describing your service'
      VALID_ARGS = [ [] ]
    end

    module Test
      DESCRIPTION = 'Test that your Conflux endpoints are set up correctly'
      VALID_ARGS = [ [], ['--production'] ]
    end

    module Submit
      DESCRIPTION = 'Submit new service to Conflux'
      VALID_ARGS = [ [] ]
    end

  end

end