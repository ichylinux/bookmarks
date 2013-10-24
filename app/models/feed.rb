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
    return true if feed.is_a?(Feedzirra::Parser::RSS)
    return true if feed.is_a?(Feedzirra::Parser::Atom)
    false
  end

  def entries
    Rails.logger.debug feed.class.name
    feed? ? feed.entries : []
  end
end
