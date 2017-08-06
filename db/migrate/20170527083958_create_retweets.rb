class CreateRetweets < ActiveRecord::Migration[5.0]
  def change
    create_table :retweets, options: 'ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci' do |t|
      t.integer :tweet_id, null: false
      t.string :twitter_user_id, null: false
      t.string :twitter_user_name, null: false
      t.string :twitter_screen_name, null: false
      t.timestamps
    end
  end
end
