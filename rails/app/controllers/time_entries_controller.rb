class TimeEntriesController < ApplicationController
  #before_filter :basecamp_auth!

  caches_action :index, :expires_in => 1.hour
 
  def index
    fetch_data_for_index
  end

  def create
    #new_req = Typhoeus::Request.get("https://protein-one.basecamphq.com/projects/#{project_id}/time_entries/new.xml", typhoeus_args.merge(:verbose => true))
    #puts new_req.body
    req = Typhoeus::Request.post("https://protein-one.basecamphq.com/projects/#{project_id}/time_entries.xml", typhoeus_args.merge({
      :verbose => true,
      :body => xml,
    }))
    if req.code == 200
      puts req.body
    end
    render :text => 'hi', :status => req.code
  end

  def update
    req = Typhoeus::Request.put("https://protein-one.basecamphq.com/time_entries/#{params[:id]}.xml", typhoeus_args.merge({
      :verbose => true,
      :body => xml,
    }))
    render :text => 'hi', :status => req.code
  end

  def destroy
    req = Typhoeus::Request.delete("https://protein-one.basecamphq.com/time_entries/#{params[:id]}.xml", typhoeus_args.merge({
      :verbose => true,
    }))
    if req.code == 200
      @id = params[:id]
    end
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
    @time_entries = time_entries_data['time-entry'].map do |te|
      TimeEntry.new.tap do |t|
        t.date = Date.parse(te['date'].first['content'])
        t.description = te['description'].first
        t.hours = te['hours'].first['content'].to_f
        t.id = te['id'].first['content'].to_i
        t.person_id = te['person-id'].first['content'].to_i
        t.todo_item_id = te['todo-item-id'].first['content'].to_i
        t.person_name = te['person-name'].first
        t.project_id = te['project-id'].first['content'].to_i
      end
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
end
