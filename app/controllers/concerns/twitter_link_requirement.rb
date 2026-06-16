module TwitterLinkRequirement
  extend ActiveSupport::Concern

  private

  def require_twitter_linked
    return if current_user.twitter_linked?

    redirect_to preferences_path, alert: t('x_accounts.errors.not_linked')
  end
end
