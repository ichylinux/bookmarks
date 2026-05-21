class DropOauth1TokenColumnsFromUsers < ActiveRecord::Migration[8.1]
  def change
    remove_column :users, :token, :string
    remove_column :users, :token_secret, :string
  end
end
