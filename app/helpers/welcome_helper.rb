module WelcomeHelper

  def favorite_theme
    return 'modern' unless user_signed_in?
    return 'modern' unless current_user.preference.present?
    return current_user.preference.theme.presence || 'modern'
  end

  def font_size_class
    return 'font-size-medium' unless user_signed_in?
    return 'font-size-medium' unless current_user.preference.present?

    font_size = current_user.preference.font_size
    return 'font-size-medium' unless Preference::FONT_SIZES.include?(font_size)

    "font-size-#{font_size}"
  end

  def drawer_ui?
    user_signed_in? && favorite_theme != 'simple'
  end
end
