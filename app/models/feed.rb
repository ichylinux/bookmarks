require 'daddy/http_client'

module FeedConst
  DEFAULT_DISPLAY_COUNT = 5
end

class Feed < ApplicationRecord
  include FeedConst
  include Crud::ByUser

  before_save :set_display_count

  def feed
    if @feed.nil?
      begin
        @feed ||= retrieve_feed
      rescue => e
        Rails.logger.error e.message
        @feed = false
      end
    end
    
    @feed
  end

  def status
    return :success if feed?
    return feed if feed.is_a?(Integer)
    :internal_server_error
  end

  def feed?
    return true if feed.is_a?(Feedjira::Parser::RSS)
    return true if feed.is_a?(Feedjira::Parser::Atom)
    return true if feed.is_a?(Feedjira::Parser::RSSFeedBurner)
    Rails.logger.info "unknown class for feed: #{feed.class.name}"
    false
  end

  def gadget_id
    "feed_#{self.id}"
  end

  def url
    feed? ? feed.url : nil
  end

  def entries
    if feed?
      feed.entries.slice(0, self.display_count)
    else
      []
    end
  end

  private

  def set_display_count
    self.display_count = DEFAULT_DISPLAY_COUNT if self.display_count.to_i == 0
  end

  def auth_salt
    Rails.application.secrets.secret_key_base[0..31]
  end

  def basic_auth_required?
    auth_user.present?
  end

  def retrieve_feed
    client = Daddy::HttpClient.new(base_url, follow_redirects: true)
    xml = client.get(request_path, request_params)

    Feedjira.parse(xml)
  end

  def base_url
    split = self.feed_url.split('/')
    url = split[0] + '//' + split[2]
  end

  def request_path
    split = self.feed_url.split('/')
    split = ('/' + split[3..-1].join('/')).split('?')
    split[0]
  end

  def request_params
    split = self.feed_url.split('/')
    split = ('/' + split[3..-1].join('/')).split('?')

    ret = {}

    split[1].split('&').each do |query|
      key_value = query.split('=')
      ret[key_value[0]] = key_value[1]
    end if split[1]
    
    ret
  end

end
