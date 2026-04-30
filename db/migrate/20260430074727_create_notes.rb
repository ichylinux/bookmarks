class CreateNotes < ActiveRecord::Migration[7.2]
  def change
    create_table :notes do |t|
      t.integer :user_id, null: false
      t.text    :body,    null: false
      t.boolean :deleted, null: false, default: false
      t.timestamps
    end

    add_index :notes, [:user_id, :created_at]
  end
end
