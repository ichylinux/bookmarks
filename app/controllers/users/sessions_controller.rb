class Users::SessionsController < Devise::SessionsController
  def create
    user = User.find_by(email: sign_in_params[:email])

    if user&.valid_password?(sign_in_params[:password])
      if user.two_factor_enabled?
        session[:otp_user_id] = user.id
        redirect_to users_two_factor_authentication_path
      else
        sign_in(user)
        respond_with user, location: after_sign_in_path_for(user)
      end
    else
      set_flash_message!(:alert, :invalid)
      redirect_to new_user_session_path
    end
  end
end
