require 'conify/helpers'

module Conify
  module CLI
    extend Conify::Helpers

    def self.start!(*args)
      # Setup StdIn/StdOut sync
      $stdin.sync = true if $stdin.isatty
      $stdout.sync = true if $stdout.isatty

      # Strip out command
      command = args.shift.strip rescue 'help'

      require 'conify/command'

      # Find and run command if it exists
      Conify::Command.find_command(command, args)

    rescue Errno::EPIPE => e
      error(e.message)
    rescue Interrupt => e
      error('Command cancelled.')
    rescue => e
      error(e)
    end

  end
end