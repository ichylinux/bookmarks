class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController

  def google_oauth2
    handle_callback('Google')
  end

  def twitter
    handle_callback('Twitter')
  end

  def twitter2
    auth = request.env["omniauth.auth"]
    @user = current_user || User.from_omniauth(auth)

    unless @user.persisted?
      redirect_to new_user_registration_url, alert: @user.errors.full_messages.join("\n")
      return
    end

    if current_user
      # Upgrade: store OAuth 2.0 tokens on the already-signed-in user
      creds = auth.credentials || {}
      expires_at = creds['expires_at'] ? Time.at(creds['expires_at'].to_i) : nil
      current_user.assign_attributes(
        oauth2_token: creds['token'],
        oauth2_refresh_token: creds['refresh_token'],
        oauth2_token_expires_at: expires_at
      )
      current_user.save(validate: false)
      redirect_to x_accounts_path, notice: t('x_accounts.oauth2_upgraded')
    else
      sign_in_and_redirect @user, event: :authentication
    end
  end

  private

  def handle_callback(kind)
    @user = User.from_omniauth(request.env["omniauth.auth"])

    if @user.persisted?
      sign_in_and_redirect @user, event: :authentication
    else
      session["devise.#{kind.downcase}_data"] = request.env["omniauth.auth"].except("extra")
      redirect_to new_user_registration_url, alert: @user.errors.full_messages.join("\n")
    end
  end

end
