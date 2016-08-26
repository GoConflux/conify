require 'conify/api/abstract_api'

class Conify::Api::Users < Conify::Api::AbstractApi

  def extension
    '/users'
  end

  # Exchange email/password for Conflux user_token
  def login(creds)
    post("#{extension}/login", data: creds)
  end

end