# coding: UTF-8

class Feed < ActiveRecord::Base

  def feed
    begin
      @feed ||= Feedzirra::Feed.fetch_and_parse(self.url)
    rescue => e
    end
  end

  def entries
    feed ? feed.entries : []
  end
end
