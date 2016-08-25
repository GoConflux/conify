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

    def with_tty(&block)
      return unless $stdin.isatty
      begin
        yield
      rescue
        # fails on windows
      end
    end

    def home_directory
      if running_on_windows?
        # This used to be File.expand_path("~"), which should have worked but there was a bug
        # when a user has a cyrillic character in their username.  Their username gets mangled
        # by a C code operation that does not respect multibyte characters
        #
        # see: https://github.com/ruby/ruby/blob/v2_2_3/win32/file.c#L47
        home = Conify::Helpers::Env['HOME']
        homedrive = Conify::Helpers::Env['HOMEDRIVE']
        homepath = Conify::Helpers::Env['HOMEPATH']
        userprofile = Conify::Helpers::Env['USERPROFILE']

        home_dir = if home
            home
          elsif homedrive && homepath
            homedrive + homepath
          elsif userprofile
            userprofile
          else
            # The expanding `~' error here does not make much sense
            # just made it match File.expand_path when no env set
            raise ArgumentError.new("couldn't find HOME environment -- expanding `~'")
          end

        home_dir.gsub(/\\/, '/')
      else
        Dir.home
      end
    end

    # Strip the protocol + following slashes off of a url
    def host
      host_url.gsub(/http:\/\/|https:\/\//, '')
    end

    def host_url
      ENV['CONFLUX_HOST'] || 'https://api.goconflux.com'
    end

    def is_rails_project?
      File.exists?(File.join(Dir.pwd, 'Gemfile'))
    end

    def is_node_project?
      File.exists?(File.join(Dir.pwd, 'package.json'))
    end

    # Get an array (of symbols) of the user-defined methods for a klass
    def manually_added_methods(klass)
      klass.instance_methods(false)
    end

    def manifest_path
      File.join(Dir.pwd, 'conflux-manifest.json')
    end

  end
end