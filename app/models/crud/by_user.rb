module Crud::ByUser

  def readable_by?(user)
    user.id == user_id
  end

  def updatable_by?(user)
    readable_by?(user)
  end

  def deletable_by?(user)
    readable_by?(user)
  end  
end