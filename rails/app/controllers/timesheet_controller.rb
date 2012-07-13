class TimesheetController < ApplicationController
  before_filter :basecamp_auth!
  caches_action :show, :expires_in => 1.hour
 
  def show
    report = Basecamp::TimeEntry.report(:subject_id => me.id)
    @time_entries = report.group_by(&:date).sort_by{|date,entries| date}
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
end
