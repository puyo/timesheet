class TimeEntriesController < ApplicationController
  #before_filter :basecamp_auth!

  caches_action :index, :expires_in => 1.hour
 
  def index
    fetch_data_for_index
  end

  def create
    #new_req = Typhoeus::Request.get("https://protein-one.basecamphq.com/projects/#{project_id}/time_entries/new.xml", typhoeus_args.merge(:verbose => true))
    #puts new_req.body
    @response = Typhoeus::Request.post("https://protein-one.basecamphq.com/projects/#{project_id}/time_entries.xml", typhoeus_args.merge({
      :verbose => true,
      :body => xml,
    }))
    return render :text => 'hi'
    if id = @response.headers_hash['Location'][/\d+$/]
      @time_entry = load_time_entry(id)
      @time_entry.project_id = project_id
    end
  end

  def update
    @response = Typhoeus::Request.put("https://protein-one.basecamphq.com/time_entries/#{params[:id]}.xml", typhoeus_args.merge({
      :verbose => true,
      :body => xml,
    }))
    @id = params[:id] if @response.code == 200
  end

  def destroy
    @response = Typhoeus::Request.delete("https://protein-one.basecamphq.com/time_entries/#{params[:id]}.xml", typhoeus_args.merge({
      :verbose => true,
    }))
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
    @me = JSON.parse(Typhoeus::Request.get('https://protein-one.basecamphq.com/me.json', typhoeus_args).body)
    projects_request = Typhoeus::Request.new('https://protein-one.basecamphq.com/projects.json', typhoeus_args)
    people_request = Typhoeus::Request.new("https://protein-one.basecamphq.com/companies/#{@me['firmId']}/people.json", typhoeus_args)
    time_entries_request = Typhoeus::Request.new('https://protein-one.basecamphq.com/time_entries/report.xml', typhoeus_args.merge(:params => {
      :subject_id => @me['id'],
    }))

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
    r = Typhoeus::Request.get("https://protein-one.basecamphq.com/time_entries/#{id}.xml", typhoeus_args)
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
    end
  end
end
