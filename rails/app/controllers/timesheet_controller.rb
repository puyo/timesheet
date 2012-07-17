class TimesheetController < ApplicationController
  before_filter :basecamp_auth!
  caches_action :show, :expires_in => 1.hour
 
  def show
    get_data
    #render :text => [@projects, @people, @time_entries].pretty_inspect
    #return
    #report = Basecamp::TimeEntry.report(:subject_id => me.id)
  end

  def old_show
    @todo_items = {}
    Basecamp::TodoList.find(:all).each do |todo_list|
    end
    @projects = {}
    Basecamp::Project.all.each do |proj|
      @projects[proj.id] = proj
      Basecamp::TodoList.find(:all, :params => {:project_id => proj.id}).each do |todo_list|
        todo_list.todo_items.each do |todo_item|
          @todo_items[todo_item.id] = todo_item
        end
      end
    end
    @people = {}
    Basecamp::Person.all.each do |person|
      @people[person.id] = person
    end
    Basecamp::TimeEntry.report(:subject_id => me.id).each do |entry|
      entry.project = @projects[entry.project_id]
      entry.person = @projects[entry.person_id]
      entry.todo_item = @todo_items[entry.todo_item_id]
    end
    @time_entries = report.group_by(&:date).sort_by{|date,entries| date}
  end

  private

  def get_data
    args = {
      :method => 'get',
      :headers => {
        'Accept' => 'application/xml',
        'Content-Type' => 'application/xml',
      },
      :timeout => 10_000, # milliseconds
      :cache_timeout => 60, # seconds
      :params => {:limit => 1_000_000},
      :verbose => false,
      :username => session[:basecamp_api_token],
      :password => 'X',
    }
    @me = JSON.parse(Typhoeus::Request.get('https://protein-one.basecamphq.com/me.json', args).body)
    projects_request = Typhoeus::Request.new('https://protein-one.basecamphq.com/projects.json', args)
    people_request = Typhoeus::Request.new("https://protein-one.basecamphq.com/companies/#{@me['firmId']}/people.json", args)
    time_entries_request = Typhoeus::Request.new('https://protein-one.basecamphq.com/time_entries/report.xml', args.dup.merge(:params => {:subject_id => @me['id']}))

    hydra = Typhoeus::Hydra.new
    hydra.queue projects_request
    hydra.queue people_request
    hydra.queue time_entries_request 
    hydra.run # this is a blocking call that returns once all requests are complete

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
