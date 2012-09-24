class BasecampProject < ActiveRecord::Base
  attr_accessible :data
  serialize :data, Hash

  def self.refresh(fresh_basecamp_projects)
    BasecampProject.transaction do
      BasecampProject.destroy_all
      fresh_basecamp_projects.each do |fresh_project|
        BasecampProject.create!(:data => fresh_project)
      end
    end
  end

  def self.find_by_basecamp_id(id)
    BasecampProject.where('data LIKE ?', %{%"id":#{id.to_i}%}).first
  end
end
