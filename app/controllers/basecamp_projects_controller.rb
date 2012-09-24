class BasecampProjectsController < ApplicationController

  def index
    @basecamp_projects = BasecampProject.all
  end

  def refresh
    me = basecamp_get_json('/me.json')
    basecamp_get_json_paginated('/projects.json') do |results|
      fresh_basecamp_projects = results.select{|project| project['status'] == 'active' }
      BasecampProject.refresh(fresh_basecamp_projects)
    end
    basecamp_run_async
    redirect_to (request.referer || basecamp_projects_url)
  end
end
