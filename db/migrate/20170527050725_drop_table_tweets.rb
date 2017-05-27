class DropTableTweets < ActiveRecord::Migration[5.0]
  def up
    drop_table :tweets
  end
  
  def down
  end
end
