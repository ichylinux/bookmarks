class RemoveColumnAuthSaltOnFeeds < ActiveRecord::Migration[5.1]
  def change
    remove_column :feeds, :auth_salt, :string
  end
end
