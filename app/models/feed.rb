# coding: UTF-8

module FeedConst
  DEFAULT_DISPLAY_COUNT = 5
end

class Feed < ActiveRecord::Base
  include FeedConst

  attr_accessor :auth_password

  before_save :set_display_count
  before_save :set_auth

  def feed
    return @feed unless @feed.nil?

    begin
      if basic_auth_required?
        @feed ||= retrieve_feed_with_basic_auth
      else
        @feed ||= Feedzirra::Feed.fetch_and_parse(self.feed_url, :ssl_verify_host => false)
      end
    rescue => e
      Rails.logger.error e.message
      @feed = false
    end
    
    feed
  end

  def feed?
    return true if feed.is_a?(Feedzirra::Parser::RSS)
    return true if feed.is_a?(Feedzirra::Parser::Atom)
    return true if feed.is_a?(Feedzirra::Parser::RSSFeedBurner)
    false
  end

  def gadget_id
    "feed_#{self.id}"
  end

  def url
    feed.url
  end

  def entries
    Rails.logger.debug feed.class.name
    feed? ? feed.entries : []
  end

  def auth_decrypted_password
    encryptor = ::ActiveSupport::MessageEncryptor.new(self.auth_salt)
    encryptor.decrypt_and_verify(self.auth_encrypted_password)
  end

  private

  def set_display_count
    self.display_count = DEFAULT_DISPLAY_COUNT if self.display_count.to_i == 0
  end

  def set_auth
    if self.auth_user.present? and self.auth_password.present?
      self.auth_salt = SecureRandom.hex(64).to_s
      encryptor = ::ActiveSupport::MessageEncryptor.new(self.auth_salt)
      self.auth_encrypted_password = encryptor.encrypt_and_sign(self.auth_password)
    end
  end

  def basic_auth_required?
    auth_user.present?
  end

  def retrieve_feed_with_basic_auth
    options = {}
    if self.auth_user.present?
      options[:auth_user] = self.auth_user
      if self.auth_password.present?
        options[:auth_password] = self.auth_password
      elsif self.auth_encrypted_password.present?
        options[:auth_password] = self.auth_decrypted_password
      end
    end

    client = Daddy::HttpClient.new(base_url, options)

    if auth_url.present?
      auth_path = '/' + auth_url.split('/')[3..-1].join('/')
      client.get(auth_path)
    end

    xml = client.get(request_path, request_params)
    Feedzirra::Feed.parse(xml)
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
