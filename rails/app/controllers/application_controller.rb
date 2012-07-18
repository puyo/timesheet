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
