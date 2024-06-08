class DropTableTweets2 < ActiveRecord::Migration[5.2]
  def change
    create_table "tweets", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
      t.integer "user_id", null: false
      t.string "tweet_id", null: false
      t.string "twitter_user_id", null: false
      t.string "twitter_user_name", null: false
      t.boolean "deleted", default: false, null: false
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.text "content"
      t.integer "retweet_count", default: 0, null: false
    end
  end
end
