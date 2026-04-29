module WelcomeHelper

  def favorite_theme
    return 'modern' unless user_signed_in?
    return 'modern' unless current_user.preference.present?
    return current_user.preference.theme.presence || 'modern'
  end
end
