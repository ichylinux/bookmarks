class ResetAuthEncryptedPasswordOnFeeds < ActiveRecord::Migration[5.1]
  def up
    Feed.update_all(['auth_encrypted_password = ?', nil])
  end

  def down
  end
end
