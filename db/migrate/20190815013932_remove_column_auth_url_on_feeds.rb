class RemoveColumnAuthUrlOnFeeds < ActiveRecord::Migration[5.2]
  def change
    remove_column :feeds, :auth_url, :string
  end
end
