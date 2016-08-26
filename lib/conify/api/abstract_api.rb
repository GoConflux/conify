require 'conify/api'
require 'conify/helpers'
require 'net/http'
require 'net/https'
require 'uri'
require 'json'

# Used to make requests to the Conflux API
class Conify::Api::AbstractApi
  include Conify::Helpers

  def get(route, data: {}, headers: {}, error_message: 'Error making request')
    form_request(Net::HTTP::Get, route, data, headers, error_message)
  end

  def post(route, data: {}, headers: {}, error_message: 'Error making request')
    json_request(Net::HTTP::Post, route, data, headers, error_message)
  end

  def put(route, data: {}, headers: {}, error_message: 'Error making request')
    json_request(Net::HTTP::Put, route, data, headers, error_message)
  end

  def delete(route, data: {}, headers: {}, error_message: 'Error making request')
    form_request(Net::HTTP::Delete, route, data, headers, error_message)
  end

  def ssl_check_win(net_http)
    case RUBY_PLATFORM
      when /win/i, /ming/i
        net_http.verify_mode = OpenSSL::SSL::VERIFY_NONE if net_http.use_ssl?
    end
  end

  def http
    uri = URI.parse(host_url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true if uri.scheme == 'https'
    ssl_check_win(http)
    http
  end

  def form_request(net_obj, route, data, headers, error_message)
    route = data.empty? ? route : "#{route}?#{URI.encode_www_form(data)}"
    request = net_obj.new("/api#{route}")
    request.add_field('Content-Type', 'application/x-www-form-urlencoded')
    add_headers(request, headers)
    response = http.request(request)
    handle_json_response(response, error_message)
  end

  def json_request(net_obj, route, data, headers, error_message)
    request = net_obj.new("/api#{route}")
    request.add_field('Content-Type', 'application/json')
    add_headers(request, headers)
    request.body = data.to_json
    response = http.request(request)
    handle_json_response(response, error_message)
  end

  def add_headers(request, headers = {})
    headers.each { |key, val| request.add_field(key, val) }
  end

  def handle_json_response(response, error_message)
    if response.code.to_i == 200
      JSON.parse(response.body) rescue {}
    else
      error(error_message)
    end
  end

end