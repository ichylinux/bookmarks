class RenameOpenBookmarksInNewTabToOpenLinksInNewTab < ActiveRecord::Migration[7.2]
  def change
    rename_column :preferences, :open_bookmarks_in_new_tab, :open_links_in_new_tab
  end
end
