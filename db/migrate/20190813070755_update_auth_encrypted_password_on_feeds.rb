class UpdateAuthEncryptedPasswordOnFeeds < ActiveRecord::Migration[5.2]
  def up
    Feed.find_each do |f|
      url = Addressable::URI.parse(f.feed_url)
      if url.host == 'mail.google.com'
        f.update_columns(auth_user: nil, auth_encrypted_password: nil, auth_url: nil)
      end
    end
  end
  
  def down
  end
end
