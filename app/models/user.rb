class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable, :two_factor_authenticatable,
         :recoverable, :rememberable, :trackable, :validatable, :omniauthable,
         :omniauth_providers => [:google_oauth2]

  has_one_time_password

  has_one :preference

  has_many :portals, -> { where( :deleted => false) }
  after_save :create_default_portal

  def self.from_omniauth(access_token)
      data = access_token.info

      user = User.where(:email => data["email"]).first
      user ||= User.create(:email => data['email'], :password => Devise.friendly_token[0,20])
      user
  end

  def admin?
    self.email == User.first.email
  end

  def preference
    super || Preference.default_preference(self)
  end

  def need_two_factor_authentication?(request = nil)
    preference.use_two_factor_authentication?
  end

  def send_two_factor_authentication_code
    LoginMailer.invoice_login(self).deliver_now
  end

  private

  def create_default_portal
    if Portal.where(:user_id => self.id).not_deleted.empty?
      p = Portal.new(:user_id => self.id, :name => 'Home')
      p.save!
    end
  end

end
