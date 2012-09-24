class CreateProjects < ActiveRecord::Migration
  def change
    create_table :projects do |t|
      t.integer :basecamp_project_id, :null => false
      t.string :basecamp_project_name, :null => false
      t.integer :hours_budgeted, :null => false, :default => 0
      t.integer :hours_spent, :null => false, :default => 0
      t.timestamp :due_date
      t.timestamp :last_refreshed
      t.timestamps
    end
  end
end
