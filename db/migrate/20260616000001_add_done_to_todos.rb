class AddDoneToTodos < ActiveRecord::Migration[8.1]
  def change
    add_column :todos, :done, :boolean, default: false, null: false
  end
end
