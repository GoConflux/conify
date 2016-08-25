require 'conify/api/abstract_api'

class Conify::Api::Users < Conify::Api::AbstractApi

  def extension
    '/users'
  end

  def login(creds)
    get("#{extension}/token_for_creds", data: creds)
  end

end