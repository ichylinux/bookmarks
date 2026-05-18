class CreateVisitedLinks < ActiveRecord::Migration[8.1]
  def change
    create_table :visited_links do |t|
      t.integer  :user_id,    null: false
      t.string   :url,        null: false, limit: 2083
      t.datetime :visited_at, null: false
      t.timestamps
    end

    add_index :visited_links, %i[user_id url], unique: true, length: { url: 767 }
  end
end
