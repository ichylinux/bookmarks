class UpdateContentOnTweets < ActiveRecord::Migration[5.0]
  def up
    Tweet.find_each(:batch_size => 100) do |tweet|
      s = tweet.client.status(tweet.tweet_id)
      tweet.update!(content: s.full_text)
    end
  end
  
  def down
  end
end
