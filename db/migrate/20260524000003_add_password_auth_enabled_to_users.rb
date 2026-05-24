class AddPasswordAuthEnabledToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :password_auth_enabled, :boolean, null: false, default: false
  end
end
