class AddColumnDefaultPriorityOnPreferences < ActiveRecord::Migration
  def change
    add_column :preferences, :default_priority, :integer
  end
end
