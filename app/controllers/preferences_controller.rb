class PreferencesController < ApplicationController

  def index
    @user = User.find(current_user.id)
    @user.build_preference unless @user.preference.present?
  end

  def create
    @user = User.find(current_user.id)
    @user.attributes = user_params

    @user.transaction do
      @user.save!
    end

    redirect_to :action => 'index'
  end

  def update
    @user = User.find(current_user.id)
    @user.attributes = user_params

    @user.transaction do
      @user.save!
    end

    redirect_to :action => 'index'
  end

  private

  def user_params
    permitted = [
      :name,
      preference_attributes: [
        :id, :theme, :use_todo, :use_two_factor_authentication, :default_priority
      ]
    ]

    params.require(:user).permit(permitted)
  end

end
