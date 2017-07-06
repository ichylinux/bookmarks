require 'sidekiq-scheduler'

class FetchRetweetsWorker
  include Sidekiq::Worker

  def perform(*args)
    Rails.logger.info 'Fetching retweets of ?? ..'
  end
end
