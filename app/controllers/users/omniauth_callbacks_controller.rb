class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController

  def google_oauth2
    handle_callback('Google')
  end

  def twitter2
    handle_callback('Twitter')
  end

  def facebook
    handle_callback('Facebook')
  end

  def mastodon
    handle_callback('Mastodon')
  end

  private

  def clear_mastodon_oauth_session!
    session.delete(:mastodon_instance)
    session.delete(:mastodon_oauth_client_id)
    session.delete(:mastodon_oauth_client_secret)
    session.delete(:mastodon_oauth_instance)
  end

  def handle_callback(kind)
    @user = User.from_omniauth(request.env["omniauth.auth"])
    clear_mastodon_oauth_session!
    sign_in_and_redirect @user, event: :authentication
  rescue ActiveRecord::RecordInvalid => e
    @user = e.record
    session["devise.#{kind.downcase}_data"] = request.env["omniauth.auth"].except("extra")
    redirect_to new_user_registration_url, alert: @user.errors.full_messages.join("\n")
  end

end
