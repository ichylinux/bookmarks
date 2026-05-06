class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  before_action :authenticate_user!
  before_action :render_font_size_migration_notice
  before_action :configure_permitted_parameters, if: :devise_controller?
  include Localization

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_in, keys: [:otp_attempt])
  end

  def render_font_size_migration_notice
    return unless user_signed_in?
    return if flash[:notice].present?

    preference = current_user.preference
    return unless preference&.font_size_notice_pending?

    flash.now[:notice] = t('preferences.font_size_migration_notice')
    preference.update_column(:font_size_notice_pending, false)
  end
end
