class Tweet < ApplicationRecord
  include Crud::ByUser

  def gadget_id
    "#{self.class.name.underscore}_#{self.id}"
  end

  
end
