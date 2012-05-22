class BasecampKeysController < ApplicationController
  def edit
    @basecamp_key = BasecampKey.new(session)
  end

  def update
    @basecamp_key = BasecampKey.new(session)
    @basecamp_key.basecamp_api_token = params[:basecamp_key][:basecamp_api_token]
    if @basecamp_key.valid?
      redirect_to root_url
    else
      render :edit
    end
  end
end
