class ApplicationController < ActionController::Base
  protect_from_forgery

  protected

  def basecamp_auth!
    if session[:basecamp_api_token]
      begin
        BasecampKey.auth(session[:basecamp_api_token])
      rescue
        session[:basecamp_api_token] = nil
        redirect_to edit_basecamp_key_url
      end
    else
      redirect_to edit_basecamp_key_url
    end
  end

  class BasecampError < RuntimeError
  end

  rescue_from BasecampError, :with => :basecamp_error

  def basecamp_error
    redirect_to edit_basecamp_key_url
  end

  def basecamp(method, path, args = {})
    result = Typhoeus::Request.send(method, [basecamp_host, path].join, typhoeus_args.merge(args))
    if method.to_s == 'get' and result.code == 401
      raise BasecampError, result.body
    end
    result
  end

  def basecamp_host
    "https://protein-one.basecamphq.com"
  end

  def typhoeus_args
    {
      :method => 'get',
      :headers => {
        'Accept' => 'application/xml',
        'Content-Type' => 'application/xml',
      },
      :timeout => 10_000, # milliseconds
      :cache_timeout => 60, # seconds
      :params => {:limit => 1_000_000},
      :verbose => false,
      :username => session[:basecamp_api_token],
      :password => 'X',
    }
  end
end
