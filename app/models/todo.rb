module TodoConst
  PRIORITIES = {
    PRIORITY_HIGH = 1 => '高',
    PRIORITY_NORMAL = 2 => '中',
    PRIORITY_LOW = 3 => '低',
  }
end

class Todo < ActiveRecord::Base
  include TodoConst
  include Crud::ByUser

  belongs_to :user

  def priority_name
    PRIORITIES[self.priority]
  end

end
