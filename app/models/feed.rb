# coding: UTF-8

class Feed < ActiveRecord::Base

  def fead
    @feed ||= Feedzirra::Feed.fetch_and_parse(self.url)
  end

  def entries
    fead.entries
  end
end
