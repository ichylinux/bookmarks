class ChangeIndexUidOnUsersToUnique < ActiveRecord::Migration[8.1]
  def change
    remove_index :users, :uid
    add_index :users, :uid, unique: true
  end
end
