class Tweet < ApplicationRecord
  include Crud::ByUser

  has_many :retweets, inverse_of: 'tweet'
  accepts_nested_attributes_for :retweets
  
  
  before_save :set_status

  def gadget_id
    "#{self.class.name.underscore}_#{self.id}"
  end

  def client
    @client ||= Twitter::REST::Client.new do |config|
      config.consumer_key    = Rails.application.secrets.omniauth_twitter_client_id
      config.consumer_secret = Rails.application.secrets.omniauth_twitter_client_secret
    end
  end

  def status
    @status ||= client.status(tweet_id)
  end

  private

  def set_status
    self.twitter_user_id = status.user.id
    self.twitter_user_name = status.user.name
    self.content = status.full_text
    self.retweet_count = status.retweet_count
  end

end
