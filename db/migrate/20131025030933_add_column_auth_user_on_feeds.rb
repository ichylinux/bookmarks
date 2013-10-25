class AddColumnAuthUserOnFeeds < ActiveRecord::Migration
  def up
    add_column :feeds, :auth_user, :string
    add_column :feeds, :auth_encrypted_password, :string
    add_column :feeds, :auth_salt, :string
  end

  def down
    remove_column :feeds, :auth_user
    remove_column :feeds, :auth_encrypted_password
    remove_column :feeds, :auth_salt
  end
end
