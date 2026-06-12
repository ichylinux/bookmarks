class Users::MastodonInstancesController < ApplicationController
  skip_before_action :authenticate_user!

  def create
    result = MastodonInstanceNormalizer.normalize(params[:instance])

    if result.success?
      session[:mastodon_instance] = result.hostname
      clear_stale_oauth_credentials!
      redirect_to omniauth_authorize_path(:user, :mastodon)
    else
      flash[:alert] = t("devise.shared.omniauth.mastodon.errors.#{result.error_key}")
      redirect_back fallback_location: new_user_session_path
    end
  end

  private

  def clear_stale_oauth_credentials!
    session.delete(:mastodon_oauth_client_id)
    session.delete(:mastodon_oauth_client_secret)
    session.delete(:mastodon_oauth_instance)
  end
end
