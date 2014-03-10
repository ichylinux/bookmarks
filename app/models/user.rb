# coding: UTF-8

class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable,
  # :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  # Setup accessible (or protected) attributes for your model
  attr_accessible :email, :password, :password_confirmation, :remember_me

  has_one :preference
  has_many :portals, :conditions => ['deleted = ?', false]

  after_save :create_default_portal

  private

  def create_default_portal
    if Portal.where(:user_id => self.id).not_deleted.count == 0
      p = Portal.new(:user_id => self.id, :name => 'Home')
      p.save!
    end
  end
  
end
