require 'conify/api/abstract_api'

class Conify::Api::Addons < Conify::Api::AbstractApi

  def extension
    '/addons'
  end

  # Push draft service to Conflux
  def push(manifest, token)
    post(
      "#{extension}/push",
      data: { manifest: manifest },
      headers: { 'Conflux-User' => token },
      show_err_response: true
    )
  end

end