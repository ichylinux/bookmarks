class AddUseBookmarkToPreferences < ActiveRecord::Migration[8.1]
  def change
    add_column :preferences, :use_bookmark, :boolean, null: false, default: true
  end
end
