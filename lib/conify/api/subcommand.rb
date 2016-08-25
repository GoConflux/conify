require 'conify/api/abstract_api'

class Conify::Api::Subcommand < Conify::Api::AbstractApi

  def extension
    '/myextension'
  end

  def my_method(args)
    get("#{extension}/endpoint")
  end

end