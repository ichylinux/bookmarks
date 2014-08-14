class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  has_one :preference

  has_many :portals, -> { where( :deleted => false) }
  after_save :create_default_portal

  def use_todo?
    return true unless preference.present?
    preference.use_todo?
  end

  private

  def create_default_portal
    if Portal.where(:user_id => self.id).not_deleted.empty?
      p = Portal.new(:user_id => self.id, :name => 'Home')
      p.save!
    end
  end

end
