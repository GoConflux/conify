require 'conify/command/abstract_command'

class Conify::Command::Global < Conify::Command::AbstractCommand

  def init

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
      DESCRIPTION = 'Init Description'
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