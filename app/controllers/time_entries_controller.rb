class TimeEntriesController < ApplicationController
  def index
    @from = params[:from] || 1.week.ago.to_date.to_s(:slug)
    @to = params[:to] || Date.today.to_s(:slug)
    fetch_data_for_index
    new_time_entry_for_form
  end

  def create
    todo_list_items = []
    lists = basecamp_get_json("/projects/#{project_id}/todo_lists.json")
    lists['records'].each do |x|
      list_id = x['id']
      items = basecamp_get_json("/todo_lists/#{list_id}/todo_items.json")
      todo_list_items += items['records']
    end
    item = todo_list_items.select{|t| t['content'] == params[:time_entry][:job_code] }.first
    if item
      new_response = basecamp_post("/todo_items/#{item['id']}/time_entries.xml", :body => xml)
    else
      @message = 'No job code found on that project'
      return
    end
    if id = new_response.headers_hash['Location'][/\d+$/]
      @time_entry = load_time_entry(id)
      @time_entry.project_id = project_id
    end
    session[:project_id] = project_id
  end

  def update
    result = basecamp_put("/time_entries/#{params[:id]}.xml", :body => xml)
    @time_entry = load_time_entry(params[:id])
    @time_entry.project_id = project_id
    session[:project_id] = project_id
  end

  def destroy
    result = basecamp_delete("/time_entries/#{params[:id]}.xml")
    @id = params[:id]
  end

  private

  def project_id
    params[:time_entry][:project_id]
  end

  def xml
    ps = params[:time_entry]
    entry = <<-ENTRY
    <time-entry>
      <date nil="true">#{ps[:date]}</date>
      <description nil="true">#{ps[:description]}</description>
      <hours type="float">#{ps[:hours]}</hours>
      <person-id nil="true">#{ps[:person_id]}</person-id>
    </time-entry>
    ENTRY
  end

  def fetch_data_for_index
    @me = basecamp_get_json('/me.json')
    basecamp_get_json_paginated('/projects.json') do |results|
      @all_projects = results
      @projects = @all_projects.select{|project| project['status'] == 'active' }
    end
    basecamp_get_json_async("/companies/#{@me['firmId']}/people.json") do |json|
      @people = json['records']
    end
    basecamp_get_xml_async('/time_entries/report.xml', :params => {
      :subject_id => @me['id'],
      :from => @from.gsub('-', ''),
      :to => @to.gsub('-', ''),
    }) do |xml|
      @time_entries = (xml['time-entry'] || []).map{|el| time_entry_from_xml(el) }
    end
    basecamp_run_async
    @projects_index = {}
    @all_projects.each do |project|
      @projects_index[project['id'].to_i] = project
    end
    @people_index = {}
    @people.each do |person|
      @people_index[person['id'].to_i] = person
    end
    @time_entries = @time_entries.group_by(&:date)
  end

  def new_time_entry_for_form
    @time_entry = TimeEntry.new
    @time_entry.person_id = @me['id']
  end

  def load_time_entry(id)
    data = basecamp_get_xml("/time_entries/#{id}.xml")
    time_entry_from_xml(data).tap{|result| result.id = id }
  end

  def time_entry_from_xml(xml_data)
    TimeEntry.new.tap do |t|
      t.date = Date.parse(xml_data['date'].first['content'])
      t.description = xml_data['description'].first
      t.hours = xml_data['hours'].first['content'].to_f
      t.id = xml_data['id'].first['content'].to_i if xml_data['id']
      t.person_id = xml_data['person-id'].first['content'].to_i
      t.todo_item_id = xml_data['todo-item-id'].first['content'].to_i
      t.person_name = xml_data['person-name'].first
      t.project_id = xml_data['project-id'].first['content'].to_i if xml_data['project-id']
      t.persisted = true
    end
  end

end
