class RenameNameToXUserNameOnUsers < ActiveRecord::Migration[8.1]
  def change
    remove_index :users, :name, if_exists: true
    rename_column :users, :name, :x_user_name
  end
end
