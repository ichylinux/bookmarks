class AddGadgetIdToVisitedLinks < ActiveRecord::Migration[8.1]
  def change
    add_column :visited_links, :gadget_id, :string, limit: 64
  end
end
