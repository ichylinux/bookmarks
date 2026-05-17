class AddPortalColumnWidthsToPreferences < ActiveRecord::Migration[8.1]
  def change
    add_column :preferences, :portal_column_widths, :json
  end
end
