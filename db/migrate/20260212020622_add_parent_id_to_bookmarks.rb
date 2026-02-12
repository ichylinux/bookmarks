class AddParentIdToBookmarks < ActiveRecord::Migration[7.2]
  def change
    add_column :bookmarks, :parent_id, :integer, null: true
    change_column_null :bookmarks, :url, true
  end
end
