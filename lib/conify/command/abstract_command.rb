require 'conify/command'
require 'conify/helpers'

class Conify::Command::AbstractCommand
  include Conify::Helpers

  attr_reader :args
  attr_reader :options

  def initialize(args = [], options = {})
    @args = args
    @options = options
  end

end