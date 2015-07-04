class UpdateDefaultPriorityOnPreferences < ActiveRecord::Migration
  def up
    Preference.update_all(['default_priority = ?', Todo::PRIORITY_NORMAL])
  end

  def down
  end
end
