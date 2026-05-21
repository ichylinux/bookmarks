module TwitterLinkRequirement
  extend ActiveSupport::Concern

  private

  def require_twitter_linked
    return if current_user.uid.present? && current_user.oauth2_token.present?

    redirect_to preferences_path, alert: t('x_accounts.errors.not_linked')
  end
end
