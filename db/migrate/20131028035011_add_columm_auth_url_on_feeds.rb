class AddColummAuthUrlOnFeeds < ActiveRecord::Migration
  def up
    add_column :feeds, :auth_url, :string
  end

  def down
    remove_column :feeds, :auth_url
  end
end
