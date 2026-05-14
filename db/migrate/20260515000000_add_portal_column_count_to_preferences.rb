class AddPortalColumnCountToPreferences < ActiveRecord::Migration[8.1]
  def change
    add_column :preferences, :portal_column_count, :integer, default: 3, null: false
  end
end
