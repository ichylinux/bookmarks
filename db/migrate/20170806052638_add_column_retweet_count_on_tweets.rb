class AddColumnRetweetCountOnTweets < ActiveRecord::Migration[5.0]
  def change
    add_column :tweets, :retweet_count, :integer, null: false, default: 0
  end
end
