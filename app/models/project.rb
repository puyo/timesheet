class Project < ActiveRecord::Base
  attr_accessible :basecamp_project_id,
    :basecamp_project_name,
    :hours_budgeted,
    :due_date

  validates_presence_of :basecamp_project_name
  validates_numericality_of :hours_budgeted, :only_integer => false, :greater_than_or_equal_to => 0

  def percent_spent
    if hours_budgeted == 0
      0
    else
      100*hours_spent / hours_budgeted
    end
  end

  def status
    if percent_spent > 100
      'danger'
    elsif percent_spent > 80
      'warning'
    else
      'success'
    end
  end

  def order_by
    -percent_spent
  end

  private

  before_validation :set_basecamp_project_name

  def set_basecamp_project_name
    if basecamp_project_id.present?
      proj = BasecampProject.find_by_basecamp_id(basecamp_project_id)
      if proj.present?
        self.basecamp_project_name = proj.data['name']
      else
        self.basecamp_project_name = 'Not found'
        self.errors.add(:base, 'Could not find the project on Basecamp')
      end
    end
  end
end
