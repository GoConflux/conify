module Conify
  module Helpers
    extend self

    def error(msg = '')
      $stderr.puts(format_with_bang(msg))
      exit(1)
    end

    # Add a bang to an error message
    def format_with_bang(message)
      return message if !message.is_a?(String)
      return '' if message.to_s.strip == ''
      " !    " + message.encode('utf-8', 'binary', invalid: :replace, undef: :replace).split("\n").join("\n !    ")
    end

    def display(msg = '')
      puts(msg)
      $stdout.flush
    end

    # convert string from underscores to camelcase
    def camelize(str)
      str.split('_').collect(&:capitalize).join
    end

    # format some data into a table to then be displayed to the user
    def to_table(data, headers)
      column_lengths = []
      gutter = 2
      table = ''

      # Figure out column widths based on longest string in each column (including the header string)
      headers.each { |header|
        width = data.map { |_| _[header] }.max_by(&:length).length

        width = header.length if width < header.length

        column_lengths << width
      }

      # format the length of a table cell string to make it as wide as the column (by adding extra spaces)
      format_row_entry = lambda { |entry, i|
        entry + (' ' * (column_lengths[i] - entry.length + gutter))
      }

      # Add headers
      headers.each_with_index { |header, i|
        table += format_row_entry.call(header, i)
      }

      table += "\n"

      # Add line breaks under headers
      column_lengths.each { |length|
        table += (('-' * length) + (' ' * gutter))
      }

      table += "\n"

      # Add rows
      data.each { |row|
        headers.each_with_index { |header, i|
          table += format_row_entry.call(row[header], i)
        }

        table += "\n"
      }

      table
    end

    # Ask a free response question with a optional prefix (prefix example --> 'Password: ')
    def ask_free_response_question(question, answer_prefix = '')
      puts question
      print answer_prefix
      response = allow_user_response
      response
    end

    # Ask a multiple choice question, with numbered answers
    def ask_mult_choice_question(question, answers)
      answer = nil

      # Prompt will continue until user has responded with one of the numbers next to an answer
      until !answer.nil? && answer.is_a?(Integer)
        puts question
        answers.each_with_index { |answer, i| puts "(#{i + 1}) #{answer}" }
        puts ''

        response = allow_user_response

        answer = answers.index(response) if answers.include?(response) rescue nil
        answer = (response.to_i - 1) if !answers[response.to_i - 1].nil? rescue nil

        question = 'Sorry I didn\'t catch that. Can you respond with the number that appears next to your answer?'
      end

      answer
    end

    def allow_user_response
      $stdin.gets.to_s.strip
    end

    def running_on_windows?
      RUBY_PLATFORM =~ /mswin32|mingw32/
    end

    def running_on_a_mac?
      RUBY_PLATFORM =~ /-darwin\d/
    end

    def ask_for_password_on_windows
      require 'Win32API'
      char = nil
      password = ''

      while char = Win32API.new('msvcrt', '_getch', [ ], 'L').Call do
        break if char == 10 || char == 13 # received carriage return or newline
        if char == 127 || char == 8 # backspace and delete
          password.slice!(-1, 1)
        else
          # windows might throw a -1 at us so make sure to handle RangeError
          (password << char.chr) rescue RangeError
        end
      end

      puts
      password
    end

    def ask_for_password
      begin
        echo_off  # make the password input hidden
        password = allow_user_response
        puts
      ensure
        echo_on  # flip input visibility back on
      end

      password
    end

    # Hide user input
    def echo_off
      with_tty do
        system 'stty -echo'
      end
    end

    # Show user input
    def echo_on
      with_tty do
        system 'stty echo'
      end
    end

    def with_tty(&block)
      return unless $stdin.isatty
      begin
        yield
      rescue
        # fails on windows
      end
    end

    def ask_for_conflux_creds
      # Ask for Conflux Credentials
      puts 'Enter your Conflux credentials.'

      # Email:
      print 'Email: '
      email = allow_user_response

      # Password
      print 'Password (typing will be hidden): '

      password = running_on_windows? ? ask_for_password_on_windows : ask_for_password

      { email: email, password: password }
    end

    # Strip the protocol + following slashes off of a url
    def host
      host_url.gsub(/http:\/\/|https:\/\//, '')
    end

    def host_url
      ENV['CONFLUX_HOST'] || 'https://api.goconflux.com'
    end

    # Get an array (of symbols) of the user-defined methods for a klass
    def manually_added_methods(klass)
      klass.instance_methods(false)
    end

    def manifest_path
      File.join(Dir.pwd, manifest_filename)
    end

    def manifest_filename
      'conflux-manifest.json'
    end

    def manifest_content
      JSON.parse(File.read(manifest_path)) rescue {}
    end

  end
end