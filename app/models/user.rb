class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :two_factor_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable, :omniauthable,
         omniauth_providers: [:google_oauth2, :twitter]

  before_create :generate_otp_secret_if_missing

  has_one :preference, inverse_of: 'user'
  accepts_nested_attributes_for :preference

  has_many :portals, -> { where(deleted: false) }, inverse_of: 'user'
  after_save :create_default_portal

  has_many :gmails, -> { where(deleted: false) }, inverse_of: 'user'

  def self.from_omniauth(access_token)
    data = access_token.info

    case access_token['provider'].to_sym
    when :twitter
      user = User.where(name: data["name"]).first
      user ||= User.create(name: data['name'], email: "dummy_#{SecureRandom.uuid}@example.com", password: Devise.friendly_token[0,20])
      user
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
