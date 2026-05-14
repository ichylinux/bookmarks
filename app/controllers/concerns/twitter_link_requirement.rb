# Enforces Phase 60 gate: X surfaces require persisted Twitter OAuth user context
# (`uid` + `token`; `name` is intentionally excluded).
module TwitterLinkRequirement
  extend ActiveSupport::Concern

  private

  def require_twitter_linked
    return if current_user.uid.present? && current_user.token.present?

    redirect_to preferences_path, alert: t('x_accounts.errors.not_linked')
  end
end
