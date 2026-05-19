class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController

  def google_oauth2
    handle_callback('Google')
  end

  def twitter
    handle_callback('Twitter')
  end

  def twitter2
    auth = request.env["omniauth.auth"]
    uid = auth.uid.to_s
    
    # Check if this X account is already linked to another user
    existing_user = User.where(uid: uid, provider: %w[twitter twitter2]).where.not(id: current_user&.id).first
    if existing_user
      redirect_to x_accounts_path, alert: "This X account is already linked to another user."
      return
    end

    if current_user
      # Upgrade: store OAuth 2.0 tokens on the already-signed-in user
      creds = auth.credentials || {}
      expires_at = creds['expires_at'] ? Time.at(creds['expires_at'].to_i) : nil
      
      # Correctly update provider and uid if they were missing or different
      current_user.assign_attributes(
        provider: 'twitter2',
        uid: uid,
        oauth2_token: creds['token'],
        oauth2_refresh_token: creds['refresh_token'],
        oauth2_token_expires_at: expires_at
      )
      current_user.save(validate: false)
      redirect_to x_accounts_path, notice: t('x_accounts.oauth2_upgraded')
    else
      @user = User.from_omniauth(auth)
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
