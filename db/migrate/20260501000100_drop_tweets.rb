class DropTweets < ActiveRecord::Migration[8.1]
  def change
    drop_table :tweets, charset: "utf8mb4", collation: "utf8mb4_general_ci" do |t|
      t.text :content, size: :medium
      t.datetime :created_at, null: false
      t.boolean :deleted, default: false, null: false
      t.integer :retweet_count, default: 0, null: false
      t.string :tweet_id, null: false
      t.string :twitter_user_id, null: false
      t.string :twitter_user_name, null: false
      t.datetime :updated_at, null: false
      t.integer :user_id, null: false
    end
  end
end
