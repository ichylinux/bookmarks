class AddOpenBookmarksInNewTabToPreferences < ActiveRecord::Migration[7.2]
  def change
    add_column :preferences, :open_bookmarks_in_new_tab, :boolean, null: false, default: false
  end
end
