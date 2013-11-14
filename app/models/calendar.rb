# coding: UTF-8

class Calendar < ActiveRecord::Base
  belongs_to :user

  def gadget_id
    "calendar_#{self.id}"
  end

  def entries
    []
  end

end
