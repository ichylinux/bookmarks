class CreateTodos < ActiveRecord::Migration
  def change
    create_table :todos do |t|
      t.integer :user_id, null: false
      t.string :title, null: false
      t.integer :priority, null: false
      t.boolean :deleted, null: false, default: false
      t.timestamps
    end
  end
end
