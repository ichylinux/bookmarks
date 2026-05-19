class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :two_factor_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable, :omniauthable,
         omniauth_providers: [:google_oauth2, :twitter2]

  encrypts :token, :token_secret
  encrypts :oauth2_token, :oauth2_refresh_token

  validates :email,
            format: { without: /\Adummy_.+@example\.com\z/, message: :dummy_email },
            on: :update

  before_create :generate_otp_secret_if_missing

  scope :active, -> { where(deleted: false) }

  has_one :preference, inverse_of: 'user'
  accepts_nested_attributes_for :preference

  # No dependent: :destroy — disabling an account is the normal lifecycle; a rare
  # hard-delete of User must not synchronously load/destroy unbounded notes (see ROADMAP).
  has_many :notes

  has_many :portals, -> { where(deleted: false) }, inverse_of: 'user'
  has_many :x_accounts, dependent: :destroy
  after_save :create_default_portal

  def self.from_omniauth(access_token)
    data = access_token.info

    case access_token['provider'].to_sym
    when :twitter2
      creds = access_token.credentials || {}
      uid = access_token.uid.to_s
      expires_at = creds['expires_at'] ? Time.at(creds['expires_at'].to_i) : nil

      user = User.active.where(uid: uid).where(provider: %w[twitter twitter2]).first
      if user
        # OAUTH-01: users.email scope is configured in devise.rb — email arrives here when granted
        attrs = {
          oauth2_token: creds['token'],
          oauth2_refresh_token: creds['refresh_token'],
          oauth2_token_expires_at: expires_at
        }
        # OAUTH-03: overwrite dummy email with real X email on re-auth when user lacks a valid email
        attrs[:email] = data['email'] if data['email'].present? && !user.has_valid_email?
        user.assign_attributes(attrs)
        user.save(validate: false)
        user
      else
        User.create!(
          provider: 'twitter2',
          uid: uid,
          oauth2_token: creds['token'],
          oauth2_refresh_token: creds['refresh_token'],
          oauth2_token_expires_at: expires_at,
          name: data['name'],
          # OAUTH-02: real email stored on create
          email: data['email'].presence || "dummy_#{SecureRandom.uuid}@example.com",
          password: Devise.friendly_token[0, 20]
        )
      end
    else
      user = User.active.where(email: data["email"]).first
      user ||= User.create(email: data['email'], password: Devise.friendly_token[0,20])
      user
    end
  end

  def display_name
    if has_valid_email?
      email
    else
      name
    end
  end

  def has_valid_email?
    return false if email.blank?
    return false if email =~ /^dummy_.+@example.com$/
    true
  end

  def admin?
    self.email == User.active.order(:id).first&.email
  end

  def destroy_account!
    return if deleted?

    now = Time.current
    update!(
      deleted: true,
      deleted_at: now,
      email: anonymized_email_for_deletion,
      name: nil,
      provider: nil,
      uid: nil,
      token: nil,
      token_secret: nil,
      oauth2_token: nil,
      oauth2_refresh_token: nil,
      oauth2_token_expires_at: nil,
      password: Devise.friendly_token[0, 20]
    )
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

  def generate_otp_secret_if_missing
    self.otp_secret ||= self.class.generate_otp_secret
  end

  def anonymized_email_for_deletion
    "deleted_#{id}_#{SecureRandom.hex(4)}@deleted.invalid"
  end

  def create_default_portal
    if Portal.where(user_id: self.id).not_deleted.empty?
      p = Portal.new(user_id: self.id, name: 'Home')
      p.save!
    end
  end

end
