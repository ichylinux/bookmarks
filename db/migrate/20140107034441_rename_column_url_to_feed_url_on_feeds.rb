class RenameColumnUrlToFeedUrlOnFeeds < ActiveRecord::Migration
  def up
    rename_column :feeds, :url, :feed_url
  end

  def down
    rename_column :feeds, :feed_url, :url
  end
end
