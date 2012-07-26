class ProjectsController < ApplicationController
  before_filter :basecamp_auth!
  respond_to :json

  def index
    @project = Basecamp::Project.find(params[:id])
    @projects = Basecamp::Project.all
    respond_with @projects
  end

  def show
    @project = Basecamp::Project.find(params[:id])
    respond_with @project
  end
end
