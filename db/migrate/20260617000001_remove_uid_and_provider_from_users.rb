class RemoveUidAndProviderFromUsers < ActiveRecord::Migration[8.1]
  def up
    remove_index :users, :uid, if_exists: true
    remove_column :users, :uid
    remove_column :users, :provider
  end

  def down
    add_column :users, :provider, :string
    add_column :users, :uid, :string
    add_index :users, :uid, unique: true
  end
end
