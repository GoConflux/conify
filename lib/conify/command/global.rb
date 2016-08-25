require 'conify/command/abstract_command'

class Conify::Command::Global < Conify::Command::AbstractCommand

  def one
  end

  #----------------------------------------------------------------------------

  module CommandInfo

    module One
      DESCRIPTION = 'One Description'
      VALID_ARGS = [ [] ]
    end

  end

end