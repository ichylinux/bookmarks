class AddHighlightedToTodos < ActiveRecord::Migration[8.1]
  def change
    add_column :todos, :highlighted, :boolean, default: false, null: false
  end
end
