class RemoveColumnAuthUserOnFeeds < ActiveRecord::Migration[5.2]
  def change
    remove_column :feeds, :auth_user, :string
  end
end
