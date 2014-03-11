module Crud::ByUser

  def readable_by?(user)
    if user.is_a?(User)
      user_id = user.id
    else
      user_id = user
    end

    self.user_id == user_id
  end

end