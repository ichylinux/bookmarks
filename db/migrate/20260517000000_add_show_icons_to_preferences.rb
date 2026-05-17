class AddShowIconsToPreferences < ActiveRecord::Migration[8.1]
  def change
    add_column :preferences, :show_icons, :boolean, default: true, null: false
  end
end
