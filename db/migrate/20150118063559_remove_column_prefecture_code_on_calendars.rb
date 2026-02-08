class RemoveColumnPrefectureCodeOnCalendars < ActiveRecord::Migration
  def up
    remove_column :calendars, :prefecture_code
  end

  def down
    add_column :calendars, :prefecture_code, :string, limit: 2
  end
end
