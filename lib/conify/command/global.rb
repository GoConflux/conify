require 'conify/command/abstract_command'
require 'conify/manifest'

class Conify::Command::Global < Conify::Command::AbstractCommand

  def init
    if File.exists?(manifest_path)
      error 'File conflux-manifest.json already exists.'
    else
      begin
        File.open(manifest_path, 'w+') do |f|
          f.write(Conify::Manifest.template)
        end

        display 'Created new manifest at conflux-manifest.json'
      rescue Exception => e
        File.delete(manifest_path)
        display "Error initializing conify manifest: #{e.message}"
      end
    end
  end

  def test

  end

  def setup

  end

  def push

  end

  #----------------------------------------------------------------------------

  module CommandInfo

    module Init
      DESCRIPTION = 'Create a new manifest describing your service'
      VALID_ARGS = [ [] ]
    end

    module Test
      DESCRIPTION = 'Test Description'
      VALID_ARGS = [ [] ]
    end

    module Setup
      DESCRIPTION = 'Setup Description'
      VALID_ARGS = [ [] ]
    end

    module Push
      DESCRIPTION = 'Push Description'
      VALID_ARGS = [ [] ]
    end

  end

end