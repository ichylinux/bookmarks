class RemoveColumnAuthEncryptedPasswordOnFeeds < ActiveRecord::Migration[5.2]
  def change
    remove_column :feeds, :auth_encrypted_password, :string
  end
end
