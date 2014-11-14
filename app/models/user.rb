class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable, :two_factor_authenticatable,
         :recoverable, :rememberable, :trackable, :validatable

  has_one_time_password

  has_one :preference

  has_many :portals, -> { where( :deleted => false) }
  after_save :create_default_portal

  def use_todo?
    return true unless preference.present?
    preference.use_todo?
  end

  def use_two_factor_authentication?
    return false unless preference.present?
    preference.use_two_factor_authentication?
  end

  def need_two_factor_authentication?(request)
    use_two_factor_authentication?
  end

  def send_two_factor_authentication_code
    LoginMailer.invoice_login(self).deliver
  end

  private

  def create_default_portal
    if Portal.where(:user_id => self.id).not_deleted.empty?
      p = Portal.new(:user_id => self.id, :name => 'Home')
      p.save!
    end
  end

end
