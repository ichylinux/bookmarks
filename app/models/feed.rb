# coding: UTF-8

class Feed < ActiveRecord::Base

  def feed
    begin
      @feed ||= Feedzirra::Feed.fetch_and_parse(self.url, :ssl_verify_host => false)
    rescue => e
      Rails.logger.error e.message
      @feed = false
    end
  end

  def feed?
    feed.is_a?(Feedzirra::Parser::RSS)
  end

  def entries
    Rails.logger.debug feed.class.name
    feed? ? feed.entries : []
  end
end
