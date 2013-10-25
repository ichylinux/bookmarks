# coding: UTF-8

class Feed < ActiveRecord::Base
  attr_accessor :auth_password

  before_save :set_auth

  def feed
    return @feed unless @feed.nil?

    begin
      split = self.url.split('/')

      url = split[0] + '//' + split[2]
      path = '/' + split[3..-1].join('/')

      options = {}
      if self.auth_user.present?
        options[:auth_user] = self.auth_user
        if self.auth_password.present?
          options[:auth_password] = self.auth_password
        elsif self.auth_encrypted_password.present?
          options[:auth_password] = self.auth_decrypted_password
        end
      end

      xml = Daddy::HttpClient.new(url, options).get(path)

      @feed ||= Feedzirra::Feed.parse(xml)

    rescue => e
      Rails.logger.error e.message
      @feed = false
    end
    
    feed
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

  def auth_decrypted_password
    encryptor = ::ActiveSupport::MessageEncryptor.new(self.auth_salt, :cipher => 'aes-256-cbc')
    encryptor.decrypt_and_verify(self.auth_encrypted_password)
  end

  private

  def set_auth
    if self.auth_user.present? and self.auth_password.present?
      self.auth_salt = SecureRandom::hex(128).to_s
      encryptor = ::ActiveSupport::MessageEncryptor.new(self.auth_salt, :cipher => 'aes-256-cbc')
      self.auth_encrypted_password = encryptor.encrypt_and_sign(self.auth_password)
    end
  end

end
