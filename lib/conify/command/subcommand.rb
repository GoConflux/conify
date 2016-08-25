require 'conify/command/abstract_command'

class Conify::Command::Subcommand < Conify::Command::AbstractCommand

  def index
  end

  def two
  end

  #----------------------------------------------------------------------------

  module CommandInfo

    module Index
      DESCRIPTION = 'My Description'
      VALID_ARGS = [ [] ]
    end

    module Two
      DESCRIPTION = 'Another Description'
      VALID_ARGS = [ [] ]
    end

  end

end