class Tweet < ApplicationRecord
  include Crud::ByUser

  before_create :fetch_tweet

  def gadget_id
    "#{self.class.name.underscore}_#{self.id}"
  end

  def client
    @client ||= Twitter::REST::Client.new do |config|
      config.consumer_key    = Rails.application.secrets.omniauth_twitter_client_id
      config.consumer_secret = Rails.application.secrets.omniauth_twitter_client_secret
    end
  end

  private

  def fetch_tweet
    s = client.status(tweet_id)
    self.twitter_user_id = s.user.id
    self.content = s.full_text
  end

end
