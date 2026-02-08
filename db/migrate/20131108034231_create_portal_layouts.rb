class CreatePortalLayouts < ActiveRecord::Migration
  def change
    create_table :portal_layouts do |t|
      t.integer :user_id, null: false
      t.integer :column_no, null: false, default: 0
      t.integer :display_order, null: false, default: 0
      t.string :gadget_id, null: false 
      t.timestamps
    end
  end
end
