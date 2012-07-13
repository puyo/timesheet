class ProjectsController < ApplicationController
  before_filter :basecamp_auth!

  respond_to :json

  # GET /projects/1.json
  def show
    @project = Basecamp::Project.find(params[:id])
    respond_with @project
  end
end
