class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :two_factor_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable, :omniauthable,
         omniauth_providers: [:google_oauth2, :twitter, :twitter2]

  encrypts :token, :token_secret
  encrypts :oauth2_token, :oauth2_refresh_token

  validates :email,
            format: { without: /\Adummy_.+@example\.com\z/, message: :dummy_email },
            on: :update

  before_create :generate_otp_secret_if_missing

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
    when :twitter
      creds = access_token.credentials || {}
      oauth_token = creds['token'].presence || creds[:token].presence
      oauth_secret = creds['secret'].presence || creds[:token_secret].presence
      uid = access_token.uid.to_s
      provider = access_token.provider.to_s

      attrs = {
        provider: provider,
        uid: uid,
        token: oauth_token,
        token_secret: oauth_secret
      }

      user = User.where(uid: uid, provider: provider).first
      if user
        user.assign_attributes(attrs)
        user.save(validate: false)
        user
      else
        User.create!(
          attrs.merge(
            name: data['name'],
            email: data['email'].presence || "dummy_#{SecureRandom.uuid}@example.com",
            password: Devise.friendly_token[0, 20]
          )
        )
      end
    when :twitter2
      creds = access_token.credentials || {}
      uid = access_token.uid.to_s
      expires_at = creds['expires_at'] ? Time.at(creds['expires_at'].to_i) : nil

      user = User.where(uid: uid).where(provider: %w[twitter twitter2]).first
      if user
        user.assign_attributes(
          oauth2_token: creds['token'],
          oauth2_refresh_token: creds['refresh_token'],
          oauth2_token_expires_at: expires_at
        )
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
          email: data['email'].presence || "dummy_#{SecureRandom.uuid}@example.com",
          password: Devise.friendly_token[0, 20]
        )
      end
    else
      user = User.where(email: data["email"]).first
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
    self.email == User.first.email
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

  def create_default_portal
    if Portal.where(user_id: self.id).not_deleted.empty?
      p = Portal.new(user_id: self.id, name: 'Home')
      p.save!
    end
  end

end
