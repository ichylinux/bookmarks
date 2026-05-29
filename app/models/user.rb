class User < ApplicationRecord
  PURGE_AFTER_DAYS = 90

  class NotPurgeableError < StandardError; end
  class LastAuthMethodError < StandardError; end

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :two_factor_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable, :omniauthable,
         omniauth_providers: [:google_oauth2, :twitter2, :facebook]

  encrypts :oauth2_token, :oauth2_refresh_token

  validates :email,
            format: { without: /\Adummy_.+@example\.com\z/, message: :dummy_email },
            on: :update

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

      user = User.active.find_by(uid: uid)
      user ||= User.active.find_by(email: data['email']) if data['email'].present?
      if user
        # OAUTH-01: users.email scope is configured in devise.rb — email arrives here when granted
        attrs = {
          provider: 'twitter2',
          x_user_name: data['name'],
          oauth2_token: creds['token'],
          oauth2_refresh_token: creds['refresh_token'],
          oauth2_token_expires_at: expires_at
        }
        attrs[:uid] = uid if user.uid.blank?
        # OAUTH-03: overwrite dummy email with real X email on re-auth when user lacks a valid email
        attrs[:email] = data['email'] if data['email'].present? && !user.has_valid_email?
        user.assign_attributes(attrs)
        user.save(validate: false)
        OauthIdentity.upsert_for!(user: user, provider: 'twitter2', uid: uid)
        user
      else
        new_user = User.create!(
          provider: 'twitter2',
          uid: uid,
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
    else
      user = User.active.where(email: data['email']).first
      user ||= User.create!(email: data['email'], password: Devise.friendly_token[0, 20])
      OauthIdentity.upsert_for!(user: user, provider: access_token['provider'], uid: access_token.uid.to_s)
      user
    end
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

  def disconnect_oauth!(provider)
    transaction do
      snapshot = self.class.find(id)
      remaining = snapshot.oauth_identities.where.not(provider: provider).count
      raise LastAuthMethodError if remaining == 0 && !snapshot.password_auth_enabled?

      rows = self.class.where(id: id, lock_version: snapshot.lock_version)
                       .update_all("lock_version = lock_version + 1")
      raise ActiveRecord::StaleObjectError.new(snapshot, "disconnect_oauth!") if rows == 0

      snapshot.oauth_identities.where(provider: provider).destroy_all
    end
  end

  def disconnect_form_auth!
    transaction do
      snapshot = self.class.find(id)
      raise LastAuthMethodError if snapshot.oauth_identities.count == 0

      rows = self.class.where(id: id, lock_version: snapshot.lock_version)
                       .update_all("lock_version = lock_version + 1")
      raise ActiveRecord::StaleObjectError.new(snapshot, "disconnect_form_auth!") if rows == 0

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

  def after_password_reset
    self.password_auth_enabled = true
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
