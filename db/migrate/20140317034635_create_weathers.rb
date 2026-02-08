class CreateWeathers < ActiveRecord::Migration
  def change
    create_table :weathers do |t|
      t.date :observation_day, null: false
      t.integer :prefecture_no, null: false
      t.integer :weather_type, null: false
      t.timestamps
    end
  end
end
