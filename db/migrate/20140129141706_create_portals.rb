class CreatePortals < ActiveRecord::Migration
  def change
    create_table :portals do |t|
      t.integer :user_id, :null => false
      t.string :name, :null => false
      t.timestamps
      t.boolean :deleted, :null => false, :default => false
    end
  end
end
