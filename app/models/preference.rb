class Preference < ActiveRecord::Base

  belongs_to :user, inverse_of: 'preference'

  def self.default_preference(user)
    ret = self.new(:user => user)
    ret.default_priority = Todo::PRIORITY_NORMAL
    ret.use_todo = true
    ret
  end

end
