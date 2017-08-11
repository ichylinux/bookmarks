require 'sidekiq-scheduler'

class FetchRetweetsWorker
  include Sidekiq::Worker

  def perform(*args)
    Tweet.find_each do |t|
      t.client.retweeters_of(t.tweet_id, count: 100).each do |user|
        rt = t.retweets.where(twitter_user_id: user.id).first
        rt ||= t.retweets.build(twitter_user_id: user.id)
        rt.twitter_user_name = user.name
        rt.twitter_screen_name = user.screen_name
      end
      t.save!
    end
  end
end
