class OauthIdentitiesController < ApplicationController
  def destroy
    provider = params[:provider].to_s

    if provider == 'form'
      destroy_form_auth
    else
      destroy_oauth(provider)
    end
  end

  private

  def destroy_oauth(provider)
    identity = current_user.oauth_identities.find_by(provider: provider)

    if identity.nil?
      redirect_to preferences_path, notice: t('oauth_identities.destroy.not_connected')
      return
    end

    remaining_oauth = current_user.oauth_identities.where.not(provider: provider).count
    if remaining_oauth == 0 && !current_user.password_auth_enabled?
      redirect_to preferences_path, alert: t('oauth_identities.destroy.last_auth_method')
      return
    end

    identity.destroy!
    redirect_to preferences_path, notice: t('oauth_identities.destroy.success', provider: provider)
  end

  def destroy_form_auth
    unless current_user.password_auth_enabled?
      redirect_to preferences_path, notice: t('oauth_identities.destroy.not_connected')
      return
    end

    if current_user.oauth_identities.count == 0
      redirect_to preferences_path, alert: t('oauth_identities.destroy.last_auth_method')
      return
    end

    current_user.disconnect_form_auth!
    redirect_to preferences_path, notice: t('oauth_identities.destroy.success', provider: 'form')
  end
end
