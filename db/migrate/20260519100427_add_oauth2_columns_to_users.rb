class AddOauth2ColumnsToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :oauth2_token, :string
    add_column :users, :oauth2_refresh_token, :string
    add_column :users, :oauth2_token_expires_at, :datetime
  end
end
