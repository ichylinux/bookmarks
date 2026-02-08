class Users::TwoFactorAuthenticationController < ApplicationController
  skip_before_action :authenticate_user!

  def show
    unless session[:otp_user_id]
      redirect_to new_user_session_path
      return
    end
  end

  def verify
    user = User.find_by(id: session[:otp_user_id])

    unless user
      redirect_to new_user_session_path
      return
    end

    if user.validate_and_consume_otp!(params[:otp_attempt])
      session.delete(:otp_user_id)
      sign_in(user)
      redirect_to after_sign_in_path_for(user)
    else
      flash.now[:alert] = t('two_factor.invalid_code')
      render :show
    end
  end

  private

  def after_sign_in_path_for(resource)
    root_path
  end
end
