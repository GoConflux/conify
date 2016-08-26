require 'conify/api/abstract_api'

class Conify::Api::Services < Conify::Api::AbstractApi

  def extension
    '/services'
  end

  # Push draft service to Conflux
  def push(manifest, token)
    get("#{extension}/push", data: manifest, headers: { 'Conflux-User' => token })
  end

end