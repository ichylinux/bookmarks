class AddShowColumnNavButtonsToPreferences < ActiveRecord::Migration[7.2]
  def change
    add_column :preferences, :show_column_nav_buttons, :boolean, default: true, null: false
  end
end
