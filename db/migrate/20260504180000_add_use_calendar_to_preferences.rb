class AddUseCalendarToPreferences < ActiveRecord::Migration[8.1]
  def change
    add_column :preferences, :use_calendar, :boolean, null: false, default: false
  end
end
