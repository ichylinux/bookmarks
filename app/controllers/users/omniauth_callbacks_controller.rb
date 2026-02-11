class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController

  def google_oauth2
    handle_callback('Google')
  end

  def twitter
    handle_callback('Twitter')
  end

  private

  def handle_callback(kind)
    @user = User.from_omniauth(request.env["omniauth.auth"])

    if @user.persisted?
      flash[:notice] = I18n.t "devise.omniauth_callbacks.success", kind: "Twitter"
      sign_in_and_redirect @user, event: :authentication
    else
      session["devise.twitter_data"] = request.env["omniauth.auth"].except("extra")
      redirect_to new_user_registration_url, alert: @user.errors.full_messages.join("\n")
    end
  end

end
