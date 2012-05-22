class ApplicationController < ActionController::Base
  protect_from_forgery

  protected

  def basecamp_auth!
    if session[:basecamp_api_token]
      begin
        Basecamp.establish_connection!('protein-one.basecamphq.com', session[:basecamp_api_token], 'X', true)
        @current_user = Basecamp::Person.me
      rescue
        session[:basecamp_api_token] = nil
        redirect_to edit_basecamp_key_url
      end
    else
      redirect_to edit_basecamp_key_url
    end
  end
end
