class ProjectsController < ApplicationController

  before_filter :load_basecamp_projects, :only => [:new, :edit, :update, :create]

  # GET /projects
  def index
    @projects = Project.all.sort_by{|p| p.order_by }

    respond_to do |format|
      format.html # index.html.erb
    end
  end

  # GET /projects/1
  def show
    @project = Project.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
    end
  end

  # GET /projects/new
  def new
    @project = Project.new

    respond_to do |format|
      format.html # new.html.erb
    end
  end

  # GET /projects/1/edit
  def edit
    @project = Project.find(params[:id])
  end

  # POST /projects
  def create
    @project = Project.new(params[:project])

    respond_to do |format|
      if @project.save
        format.html { redirect_to projects_path, :notice => 'Project was successfully created.' }
      else
        format.html { render :action => "new" }
      end
    end
  end

  # PUT /projects/1
  def update
    @project = Project.find(params[:id])

    respond_to do |format|
      if @project.update_attributes(params[:project])
        format.html { redirect_to projects_path, :notice => 'Project was successfully updated.' }
      else
        format.html { render :action => "edit" }
      end
    end
  end

  # DELETE /projects/1
  def destroy
    @project = Project.find(params[:id])
    @project.destroy

    respond_to do |format|
      format.html { redirect_to projects_url }
    end
  end

  def measure
    me = basecamp_get_json('/me.json')
    results = Hash.new{|h,k| h[k] = [] }
    projects = Project.all
    projects.each do |project|
      basecamp_get_xml_async("/projects/#{project.basecamp_project_id}/time_entries.xml") do |entries_data|
        entries = entries_data['time-entry']
        results[project.id] += entries
      end
    end
    basecamp_run_async

    Project.transaction do
      projects.each do |project|
        entries = results[project.id]
        times = entries.map{|e| e['hours'].first['content'].to_f }
        project.hours_spent = times.sum
        project.save!
      end
    end

    redirect_to (request.referer || basecamp_projects_url)
  end

  private

  def load_basecamp_projects
    @basecamp_projects = BasecampProject.all
  end

end
