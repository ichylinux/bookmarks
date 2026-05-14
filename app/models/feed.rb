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

  # Remote icon URL from parsed RSS/Atom metadata. May trigger #feed fetch.
  def gadget_title_icon_image_url
    normalize_feed_asset_url(raw_feed_icon_url_from_parser)
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

  def retrieve_feed
    client = Daddy::HttpClient.new(base_url, follow_redirects: true)
    xml = client.get(request_path, request_params)

    Feedjira.parse(xml)
  end

  def raw_feed_icon_url_from_parser
    return nil unless feed?

    f = feed
    if f.is_a?(Feedjira::Parser::Atom)
      return f.icon.to_s.strip.presence
    end
    if f.respond_to?(:image) && f.image.respond_to?(:url)
      return f.image.url.to_s.strip.presence
    end

    nil
  end

  def normalize_feed_asset_url(ref)
    ref = ref.to_s.strip
    return nil if ref.blank?
    return "https:#{ref}" if ref.start_with?('//')

    if ref.match?(/\Ahttps?:\/\//i)
      return ref if http_https_scheme?(ref)

      return nil
    end

    if ref.start_with?('/')
      base = url
      return nil if base.blank?

      joined = URI.join(base, ref).to_s
      return joined if http_https_scheme?(joined)
    end

    nil
  rescue URI::InvalidURIError, ArgumentError
    nil
  end

  def http_https_scheme?(u)
    uri = URI.parse(u)
    %w[http https].include?(uri.scheme&.downcase)
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
