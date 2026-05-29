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
    unless current_user.oauth_identities.exists?(provider: provider)
      redirect_to preferences_path, notice: t('oauth_identities.destroy.not_connected')
      return
    end

    current_user.disconnect_oauth!(provider, lock_version: params.require(:lock_version).to_i)
    redirect_to preferences_path, notice: t('oauth_identities.destroy.success', provider: provider)
  rescue User::LastAuthMethodError
    redirect_to preferences_path, alert: t('oauth_identities.destroy.last_auth_method')
  rescue ActiveRecord::StaleObjectError
    redirect_to preferences_path, alert: t('oauth_identities.destroy.stale')
  end

  def destroy_form_auth
    unless current_user.password_auth_enabled?
      redirect_to preferences_path, notice: t('oauth_identities.destroy.not_connected')
      return
    end

    current_user.disconnect_form_auth!(lock_version: params.require(:lock_version).to_i)
    redirect_to preferences_path, notice: t('oauth_identities.destroy.success', provider: 'form')
  rescue User::LastAuthMethodError
    redirect_to preferences_path, alert: t('oauth_identities.destroy.last_auth_method')
  rescue ActiveRecord::StaleObjectError
    redirect_to preferences_path, alert: t('oauth_identities.destroy.stale')
  end
end
