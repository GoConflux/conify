require 'conify/test/api_test'
require 'conify/sso'
require 'mechanize'

class Conify::SsoTest < Conify::ApiTest

  OUTPUT_COMPLETION = true

  def agent
    @agent ||= Mechanize.new
  end

  def mechanize_get
    if @sso.POST?
      page = agent.post(@sso.post_url, @sso.query_params)
    else
      page = agent.get(@sso.get_url)
    end

    return page, 200
  rescue Mechanize::ResponseCodeError => error
    return nil, error.response_code.to_i
  rescue Errno::ECONNREFUSED
    error "SSO Test: connection refused to #{url}"
  end

  def test(*args)
    @sso = Conify::Sso.new(data)
    super(*args)
  end

  def call
    error 'SSO Test: Need an sso salt to perform sso test' unless data['api']['sso_salt']

    test 'validates token' do
      @sso.token = 'invalid'
      page, respcode = mechanize_get
      error "SSO Test: expected 403, got #{respcode}" unless respcode == 403
      true
    end

    test 'validates timestamp' do
      @sso.timestamp = (Time.now - (60 * 6)).to_i
      page, respcode = mechanize_get
      error "SSO Test: expected 403, got #{respcode}" unless respcode == 403
      true
    end

    page_logged_in = nil

    test 'logs in' do
      page_logged_in, respcode = mechanize_get
      error "SSO Test: expected 200, got #{respcode}" unless respcode == 200
      true
    end
  end

end
