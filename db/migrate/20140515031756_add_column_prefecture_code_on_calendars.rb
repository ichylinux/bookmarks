class AddColumnPrefectureCodeOnCalendars < ActiveRecord::Migration
  def up
    add_column :calendars, :prefecture_code, :string, limit: 2
  end

  def down
    remove_column :calendars, :prefecture_code
  end
end
