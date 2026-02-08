class AddColumnUseTodoOnPreferences < ActiveRecord::Migration
  def up
    add_column :preferences, :use_todo, :boolean, null: false, default: false
  end

  def down
    remove_column :preferences, :use_todo
  end
end
