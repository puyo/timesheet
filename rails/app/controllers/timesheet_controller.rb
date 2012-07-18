class TimesheetController < ApplicationController
  #before_filter :basecamp_auth!
  caches_action :show, :expires_in => 1.hour
 
  def show
    @me = JSON.parse(Typhoeus::Request.get('https://protein-one.basecamphq.com/me.json', typhoeus_args).body)
    projects_request = Typhoeus::Request.new('https://protein-one.basecamphq.com/projects.json', typhoeus_args)
    people_request = Typhoeus::Request.new("https://protein-one.basecamphq.com/companies/#{@me['firmId']}/people.json", typhoeus_args)
    time_entries_request = Typhoeus::Request.new('https://protein-one.basecamphq.com/time_entries/report.xml', typhoeus_args.dup.merge(:params => {:subject_id => @me['id']}))

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
