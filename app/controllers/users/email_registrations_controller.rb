class Users::EmailRegistrationsController < ApplicationController
  before_action :require_dummy_email

  def new
    @user = current_user
  end

  def create
    @user = current_user
    @user.email = email_registration_params[:email]
    begin
      saved = @user.save
    rescue ActiveRecord::RecordNotUnique
      @user.errors.add(:email, :taken)
      render :new, status: :unprocessable_entity
      return
    end

    if saved
      flash[:notice] = t('email_registrations.saved')
      redirect_to preferences_path
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def require_dummy_email
    redirect_to preferences_path if current_user.has_valid_email?
  end

  def email_registration_params
    params.require(:email_registration).permit(:email)
  end
end
