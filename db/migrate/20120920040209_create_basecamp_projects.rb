class CreateBasecampProjects < ActiveRecord::Migration
  def change
    create_table :basecamp_projects do |t|
      t.text :data

      t.timestamps
    end
  end
end
