class Users::AccountDeletionsController < ApplicationController
  CONFIRMATION_TOKEN = 'DELETE'

  def new
  end

  def destroy
    unless params[:confirmation].to_s.strip == CONFIRMATION_TOKEN
      flash.now[:alert] = t('account_deletions.destroy.confirmation_mismatch')
      render :new, status: :unprocessable_entity
      return
    end

    user = current_user
    user.destroy_account!
    sign_out(user)
    redirect_to root_path, notice: t('account_deletions.destroy.success')
  end
end
