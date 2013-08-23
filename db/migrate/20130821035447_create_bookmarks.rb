class CreateBookmarks < ActiveRecord::Migration
  def change
    create_table :bookmarks do |t|
      t.integer :user_id, :null => false
      t.string :title, :null => false
      t.string :url, :null => false
      t.boolean :deleted, :null => false, :default => false
      t.timestamps
    end
  end
end
