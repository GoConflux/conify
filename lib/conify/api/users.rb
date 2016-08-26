require 'conify/api/abstract_api'

class Conify::Api::Users < Conify::Api::AbstractApi

  def extension
    '/users'
  end

  # Get a user token in exchange for email/password
  def login(creds)
    get("#{extension}/token_for_creds", data: creds)
  end

end