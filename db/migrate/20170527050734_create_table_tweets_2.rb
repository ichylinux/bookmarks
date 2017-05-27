class CreateTableTweets2 < ActiveRecord::Migration[5.0]
  def change
    create_table :tweets do |t|
      t.integer :user_id, null: false
      t.string :tweet_id, null: false
      t.string :twitter_user_id, null: false
      t.string :twitter_user_name, null: false
      t.boolean :deleted, null: false, default: false
      t.timestamps
      t.text :content
    end
  end
end
