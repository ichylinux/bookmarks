class AddSoftDeleteToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :deleted, :boolean, null: false, default: false
    add_column :users, :deleted_at, :datetime
  end
end
