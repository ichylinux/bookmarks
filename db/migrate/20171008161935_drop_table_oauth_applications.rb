class DropTableOauthApplications < ActiveRecord::Migration[5.0]
  def up
    drop_table :oauth_access_grants
    drop_table :oauth_access_tokens
    drop_table :oauth_applications
  end
  def down
  end
end
