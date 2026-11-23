class AddLikedAtToVisitedLinks < ActiveRecord::Migration[8.1]
  def change
    add_column :visited_links, :liked_at, :datetime
    add_index :visited_links, [:user_id, :liked_at], name: 'index_visited_links_on_user_id_and_liked_at'
  end
end