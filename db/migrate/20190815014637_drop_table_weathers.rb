class DropTableWeathers < ActiveRecord::Migration[5.2]
  def up
    drop_table :weathers
  end
  
  def down
    raise 'cannot go back'
  end
end
