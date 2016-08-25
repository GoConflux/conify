require 'conify/api/abstract_api'

class Conify::Api::Services < Conify::Api::AbstractApi

  def extension
    '/services'
  end

  def submit(manifest, token)
    get("#{extension}/endpoint", data: manifest, headers: { 'Conflux-User' => token })
  end

end