class User < ApplicationRecord
  PURGE_AFTER_DAYS = 90

  class NotPurgeableError < StandardError; end
  class LastAuthMethodError < StandardError; end

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :two_factor_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable, :omniauthable,
         omniauth_providers: [:google_oauth2, :twitter2, :facebook, :mastodon]

  encrypts :oauth2_token, :oauth2_refresh_token

  validates :email,
            format: { without: /\Adummy_.+@example\.com\z/, message: :dummy_email },
            on: :update
  validates :mastodon_handle,
            uniqueness: { allow_nil: true },
            on: :update

  before_validation :normalize_mastodon_handle, if: -> { will_save_change_to_mastodon_handle? }
  before_create :generate_otp_secret_if_missing
  before_save :after_password_reset,
    if: -> { encrypted_password_changed? && reset_password_token_was.present? }

  scope :active, -> { where(deleted: false) }
  scope :purgeable, lambda {
    where(deleted: true)
      .where.not(deleted_at: nil)
      .where('deleted_at <= ?', PURGE_AFTER_DAYS.days.ago)
  }

  has_many :oauth_identities

  has_one :preference, inverse_of: 'user'
  accepts_nested_attributes_for :preference

  has_many :bookmarks
  has_many :feeds
  has_many :mastodon_accounts
  has_many :notes
  has_many :portals, -> { where(deleted: false) }, inverse_of: 'user'
  has_many :portal_layouts
  has_many :todos
  has_many :visited_links
  has_many :x_accounts
  has_many :x_api_calls

  after_save :create_default_portal

  def self.from_omniauth(access_token)
    data = access_token.info

    case access_token['provider'].to_sym
    when :twitter2
      creds = access_token.credentials || {}
      uid = access_token.uid.to_s
      expires_at = creds['expires_at'] ? Time.at(creds['expires_at'].to_i) : nil

      user = find_twitter_oauth_user(uid)
      user ||= User.active.find_by(email: data['email']) if data['email'].present?
      if user
        # OAUTH-01: users.email scope is configured in devise.rb — email arrives here when granted
        attrs = {
          x_user_name: data['name'],
          oauth2_token: creds['token'],
          oauth2_refresh_token: creds['refresh_token'],
          oauth2_token_expires_at: expires_at
        }
        # OAUTH-03: overwrite dummy email with real X email on re-auth when user lacks a valid email
        attrs[:email] = data['email'] if data['email'].present? && !user.has_valid_email?
        user.assign_attributes(attrs)
        user.save(validate: false)
        OauthIdentity.upsert_for!(user: user, provider: 'twitter2', uid: uid)
        user
      else
        new_user = User.create!(
          oauth2_token: creds['token'],
          oauth2_refresh_token: creds['refresh_token'],
          oauth2_token_expires_at: expires_at,
          x_user_name: data['name'],
          # OAUTH-02: real email stored on create
          email: data['email'].presence || "dummy_#{SecureRandom.uuid}@example.com",
          password: Devise.friendly_token[0, 20]
        )
        OauthIdentity.upsert_for!(user: new_user, provider: 'twitter2', uid: uid)
        new_user
      end
    when :facebook
      user = User.active.where(email: data['email']).first
      user ||= User.create!(email: data['email'], password: Devise.friendly_token[0, 20])
      OauthIdentity.upsert_for!(user: user, provider: 'facebook', uid: access_token.uid.to_s)
      user
    when :mastodon
      instance = mastodon_oauth_instance(access_token, data)
      account_id = access_token.uid.to_s
      composite_uid = "#{instance}:#{account_id}"
      username = data['nickname'].to_s.presence

      user = find_mastodon_oauth_user(composite_uid)
      if user
        OauthIdentity.upsert_for!(user: user, provider: 'mastodon', uid: composite_uid)
        return user
      end

      if username.present?
        handle_result = MastodonHandleNormalizer.normalize("#{username}@#{instance}")
        if handle_result.success?
          user = User.active.find_by(mastodon_handle: handle_result.handle)
          if user
            return link_mastodon_oauth_user!(user, composite_uid)
          end
        end
      end

      new_user = User.create!(
        email: data['email'].presence || "dummy_#{SecureRandom.uuid}@example.com",
        password: Devise.friendly_token[0, 20]
      )
      OauthIdentity.upsert_for!(user: new_user, provider: 'mastodon', uid: composite_uid)
      new_user
    else
      user = User.active.where(email: data['email']).first
      user ||= User.create!(email: data['email'], password: Devise.friendly_token[0, 20])
      OauthIdentity.upsert_for!(user: user, provider: access_token['provider'], uid: access_token.uid.to_s)
      user
    end
  end

  def oauth_identity_for(provider)
    oauth_identities.find_by(provider: provider.to_s)
  end

  def twitter_oauth_uid
    oauth_identity_for('twitter2')&.uid
  end

  def twitter_linked?
    twitter_oauth_uid.present? && oauth2_token.present?
  end

  def display_name
    if has_valid_email?
      email
    else
      x_user_name
    end
  end

  def has_valid_email?
    return false if email.blank?
    return false if email =~ /^dummy_.+@example.com$/
    true
  end

  def destroy_account!
    return if deleted?

    now = Time.current
    # Skip validations: X-only users may still have a dummy email, which is valid at create time.
    update_columns(deleted: true, deleted_at: now, updated_at: now)
  end

  def purgeable?
    deleted? && deleted_at.present? && deleted_at <= PURGE_AFTER_DAYS.days.ago
  end

  def purge!
    raise NotPurgeableError unless purgeable?

    user_id = id
    transaction do
      Bookmark.where(user_id: user_id).delete_all
      Feed.where(user_id: user_id).delete_all
      MastodonAccount.where(user_id: user_id).delete_all
      Note.where(user_id: user_id).delete_all
      OauthIdentity.where(user_id: user_id).delete_all
      PortalLayout.where(user_id: user_id).delete_all
      Portal.where(user_id: user_id).delete_all
      Preference.where(user_id: user_id).delete_all
      Todo.where(user_id: user_id).delete_all
      VisitedLink.where(user_id: user_id).delete_all
      XAccount.where(user_id: user_id).delete_all
      XApiCall.where(user_id: user_id).delete_all
      delete
    end
  end

  def active_for_authentication?
    super && !deleted?
  end

  def inactive_message
    deleted? ? :deleted_account : super
  end

  def preference
    super || Preference.default_preference(self)
  end

  def two_factor_enabled?
    otp_required_for_login?
  end

  def enable_two_factor!
    update!(otp_required_for_login: true)
  end

  def disconnect_oauth!(provider, lock_version: self.lock_version)
    transaction do
      snapshot = self.class.find(id)
      remaining = snapshot.oauth_identities.where.not(provider: provider).count
      raise LastAuthMethodError if remaining == 0 && !snapshot.password_auth_enabled?

      rows = self.class.where(id: id, lock_version: lock_version)
                       .update_all("lock_version = lock_version + 1")
      raise ActiveRecord::StaleObjectError.new(self, "disconnect_oauth!") if rows == 0

      snapshot.oauth_identities.where(provider: provider).destroy_all
    end
  end

  def disconnect_form_auth!(lock_version: self.lock_version)
    transaction do
      snapshot = self.class.find(id)
      raise LastAuthMethodError if snapshot.oauth_identities.count == 0

      rows = self.class.where(id: id, lock_version: lock_version)
                       .update_all("lock_version = lock_version + 1")
      raise ActiveRecord::StaleObjectError.new(self, "disconnect_form_auth!") if rows == 0

      self.lock_version = lock_version + 1
      update_columns(
        password_auth_enabled: false,
        encrypted_password: Devise::Encryptor.digest(self.class, SecureRandom.hex)
      )
    end
  end

  def disable_two_factor!
    update!(otp_required_for_login: false)
    regenerate_otp_secret!
  end

  def regenerate_otp_secret!
    update!(otp_secret: self.class.generate_otp_secret)
  end

  def otp_provisioning_uri
    label = "Bookmarks:#{email}"
    otp = ROTP::TOTP.new(otp_secret, issuer: 'Bookmarks')
    otp.provisioning_uri(label)
  end

  private

  def self.mastodon_oauth_instance(access_token, data)
    data['instance'].presence ||
      access_token.extra&.dig('instance').presence ||
      access_token.extra&.dig(:instance).presence
  end
  private_class_method :mastodon_oauth_instance

  def self.find_twitter_oauth_user(uid)
    User.active
        .joins(:oauth_identities)
        .find_by(oauth_identities: { provider: 'twitter2', uid: uid })
  end
  private_class_method :find_twitter_oauth_user

  def self.find_mastodon_oauth_user(composite_uid)
    User.active
        .joins(:oauth_identities)
        .find_by(oauth_identities: { provider: 'mastodon', uid: composite_uid })
  end
  private_class_method :find_mastodon_oauth_user

  def self.link_mastodon_oauth_user!(user, composite_uid)
    OauthIdentity.upsert_for!(user: user, provider: 'mastodon', uid: composite_uid)
    user
  rescue OauthIdentity::UidOwnedByAnotherUserError
    find_mastodon_oauth_user(composite_uid) || raise
  end
  private_class_method :link_mastodon_oauth_user!

  def after_password_reset
    self.password_auth_enabled = true
  end

  def normalize_mastodon_handle
    raw = mastodon_handle.to_s
    if raw.strip.blank?
      self.mastodon_handle = nil
      return
    end

    result = MastodonHandleNormalizer.normalize(raw)
    if result.success?
      self.mastodon_handle = result.handle
    else
      errors.add(:mastodon_handle, result.error_key)
    end
  end

  def generate_otp_secret_if_missing
    self.otp_secret ||= self.class.generate_otp_secret
  end

  def create_default_portal
    if Portal.where(user_id: self.id).not_deleted.empty?
      p = Portal.new(user_id: self.id, name: 'Home')
      p.save!
    end
  end

end
