class AddIndexUidOnUsers < ActiveRecord::Migration[8.1]
  def change
    add_index :users, :uid
  end
end
