class ChangeColumnUserIdOnPreferences < ActiveRecord::Migration
  def up
    change_column :preferences, :user_id, :integer, :null => false
  end

  def down
    change_column :preferences, :user_id, :integer, :null => true
  end
end
