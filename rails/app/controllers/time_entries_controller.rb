class TimeEntriesController < ApplicationController
  before_filter :basecamp_auth!
  respond_to :js

  def create
    @time_entry = TimeEntry.create!(params[:time_entry])
    respond_to do |format|
      format.js
    end
  end

  def update
    @time_entry = TimeEntry.update!(params[:time_entry])
    respond_to do |format|
      format.js
    end
  end

  def destroy
    @time_entry = TimeEntry.destroy!(params[:id])
    respond_to do |format|
      format.js
    end
  end
end
