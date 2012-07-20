class TimeEntry
  extend ActiveModel::Naming 
  include ActiveModel::Serialization
  include ActiveModel::Validations
  include ActiveModel::Conversion

  def self.create(id, attributes, basecamp_key)
    e = Basecamp::TimeEntry.new(attributes)
    e.save!
    from_basecamp(e)
  end

  def self.update(id, attributes, basecamp_key)
    e = Basecamp::TimeEntry.find(id)
    e.attributes = attributes
    e.save!
    from_basecamp(e)
  end

  def self.destroy(id, basecamp_key)
  end

  attr_accessor :id, :date, :person_id, :project_id, :todo_item_id, :hours, :description, :job_code, :person_name, :project_name, :persisted
  
  def persisted?
    @persisted
  end

  def initialize(attributes = {})
    self.date = Date.today
    self.attributes = attributes
    self.persisted = false
  end

  def attributes=(attributes)
    attributes.each do |k, v|
      send("#{k}=", v)
    end
  end

  def to_param
    id
  end

  def self.from_basecamp(bc_time_entry)
    TimeEntry.new.tap do |t|
      t.date = bc_time_entry.date
      t.person_name = bc_time_entry.person_name
      t.person_id = bc_time_entry.person_id
      t.project_id = bc_time_entry.project_id
      t.hours = bc_time_entry.hours
      t.todo_item_id = bc_time_entry.todo_item_id
      t.description = bc_time_entry.description
      #t.job_code = bc_time_entry.job_code
      t.persisted = true
    end
  end
end
