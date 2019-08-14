class CreateGmails < ActiveRecord::Migration[5.2]
  def change
    create_table :gmails do |t|
      t.integer :user_id, null: false
      t.string :title, null: false
      t.string :labels
      t.boolean :deleted, null: false, default: false
      t.timestamps
    end
  end
end
