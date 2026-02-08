class DropGmails < ActiveRecord::Migration[7.2]
  def change
    drop_table :gmails do |t|
      t.integer "user_id", null: false
      t.string "title", null: false
      t.string "labels"
      t.boolean "deleted", default: false, null: false
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.integer "display_count", default: 0, null: false
    end
  end
end
