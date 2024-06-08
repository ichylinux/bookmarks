class DropTableRetweets < ActiveRecord::Migration[5.2]
  def change
    drop_table "retweets", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4", force: :cascade do |t|
      t.integer "tweet_id", null: false
      t.string "twitter_user_id", null: false
      t.string "twitter_user_name", null: false
      t.string "twitter_screen_name", null: false
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
    end
  end
end
