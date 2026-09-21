class AddUserIdAndVisitedAtIndexToVisitedLinks < ActiveRecord::Migration[8.1]
  def change
    add_index :visited_links, [:user_id, :visited_at],
              name: 'index_visited_links_on_user_id_and_visited_at'
  end
end
