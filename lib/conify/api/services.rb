require 'conify/api/abstract_api'

class Conify::Api::Services < Conify::Api::AbstractApi

  def extension
    '/services'
  end

  # Submit service to Conflux
  def submit(manifest, token)
    get("#{extension}/submit", data: manifest, headers: { 'Conflux-User' => token })
  end

end