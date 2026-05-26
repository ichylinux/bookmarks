class ChangeColumnUseBookmarkOnPreferences < ActiveRecord::Migration[8.1]
  def change
    change_column :preferences, :use_bookmark, :boolean, null: false, default: false
  end
end
