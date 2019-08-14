class Gmail < ApplicationRecord
  belongs_to :user, inverse_of: 'gmails'

  def gadget_id
    "gmail_#{self.id}"
  end
end
