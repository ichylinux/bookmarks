class AddColumnShowWeatherOnCalendars < ActiveRecord::Migration
  def up
    add_column :calendars, :show_weather, :boolean, :null => false, :default => false
  end

  def down
    remove_column :calendars, :show_weather
  end
end
