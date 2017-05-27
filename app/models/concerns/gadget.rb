module Gadget
  extend ActiveSupport::Concern

  attr_reader :user

  def initialize(user)
    @user = user
  end

  def gadget_id
    self.class.name.underscore
  end

  def visible?
    entries.present?
  end

  def entries
    raise 'entries not defined'
  end
end