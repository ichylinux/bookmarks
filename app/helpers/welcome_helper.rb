module WelcomeHelper

  def favorite_theme
    return nil unless user_signed_in?
    return nil unless current_user.preference.present?
    return current_user.preference.theme
  end
end
