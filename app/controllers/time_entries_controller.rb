class TimeEntriesController < ApplicationController
  #before_filter :basecamp_auth!

  caches_action :index, :expires_in => 1.hour
 
  def index
    @from = params[:from] || 1.week.ago.to_date.to_s(:slug)
    @to = params[:to] || Date.today.to_s(:slug)
    fetch_data_for_index
  end

  def create
    todo_list_items = []
    lists = JSON.parse(basecamp(:get, "/projects/#{project_id}/todo_lists.json", :verbose => true).body)
    lists['records'].each do |x|
      list_id = x['id']
      items = JSON.parse(basecamp(:get, "/todo_lists/#{list_id}/todo_items.json", :verbose => true).body)
      todo_list_items += items['records']
    end
    item = todo_list_items.select{|t| t['content'] == params[:time_entry][:job_code] }.first
    if item
      new_response = basecamp(:post, "/todo_items/#{item['id']}/time_entries.xml", :verbose => true, :body => xml)
    else
      @message = 'No job code found on that project'
      return
      #new_response = basecamp(:post, "/projects/#{project_id}/time_entries.xml", :verbose => true, :body => xml)
    end
    if id = new_response.headers_hash['Location'][/\d+$/]
      @time_entry = load_time_entry(id)
      @time_entry.project_id = project_id
    end
  end

  def update
    @response = basecamp(:put, "/time_entries/#{params[:id]}.xml", :verbose => true, :body => xml)
    id = params[:id] if @response.code == 200
    @time_entry = load_time_entry(id)
    @time_entry.project_id = project_id
  end

  def destroy
    @response = basecamp(:delete, "/time_entries/#{params[:id]}.xml", :verbose => true)
    @id = params[:id] if @response.code == 200
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
    @me = JSON.parse(basecamp(:get, '/me.json').body)
    projects_request = basecamp(:new, '/projects.json')
    people_request = basecamp(:new, "/companies/#{@me['firmId']}/people.json")
    time_entries_request = basecamp(:new, '/time_entries/report.xml', :params => {
      :subject_id => @me['id'],
      :from => @from.gsub('-', ''),
      :to => @to.gsub('-', ''),
    })

    hydra = Typhoeus::Hydra.new
    hydra.queue projects_request
    hydra.queue people_request
    hydra.queue time_entries_request 
    hydra.run

    projects_data = JSON.parse(projects_request.handled_response.body)
    people_data = JSON.parse(people_request.handled_response.body)
    time_entries_data = XmlSimple.xml_in(time_entries_request.handled_response.body)

    @projects = projects_data['records']
    @people = people_data['records']
    @time_entries = time_entries_data['time-entry'].map do |xml_data|
      time_entry_from_xml(xml_data)
    end

    @projects_index = {}
    @projects.each do |project|
      @projects_index[project['id'].to_i] = project
    end

    @people_index = {}
    @people.each do |person|
      @people_index[person['id'].to_i] = person
    end

    @time_entries.each do |entry|
      entry.project_name = @projects_index[entry.project_id]
    end

    @time_entries = @time_entries.group_by(&:date).sort_by{|date,entries| date}
    @time_entry = TimeEntry.new
    @time_entry.person_id = @me['id']
  end

  def load_time_entry(id)
    r = basecamp(:get, "/time_entries/#{id}.xml")
    if r.code == 200
      data = XmlSimple.xml_in(r.body)
      time_entry_from_xml(data).tap{|result| result.id = id }
    else
      nil
    end
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

  def basecamp(method, path, args = {})
    Typhoeus::Request.send(method, [basecamp_host, path].join, typhoeus_args.merge(args))
  end

  def basecamp_host
    "https://protein-one.basecamphq.com"
  end
end
