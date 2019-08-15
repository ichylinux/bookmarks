class RemoveColumnShowWeatherOnCalendars < ActiveRecord::Migration[5.2]
  def change
    remove_column :calendars, :show_weather, :boolean, null: false, default: false
  end
end
