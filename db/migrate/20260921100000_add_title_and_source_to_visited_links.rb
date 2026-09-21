class AddTitleAndSourceToVisitedLinks < ActiveRecord::Migration[8.1]
  def change
    add_column :visited_links, :title, :string, limit: 2083
    add_column :visited_links, :source, :string, limit: 32
  end
end
