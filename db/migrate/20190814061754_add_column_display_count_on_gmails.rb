class AddColumnDisplayCountOnGmails < ActiveRecord::Migration[5.2]
  def change
    add_column :gmails, :display_count, :integer, null: false, default: 0
  end
end
