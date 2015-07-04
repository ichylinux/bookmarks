class PreferencesController < ApplicationController

  def index
    @preference = current_user.preference
  end

  def create
    @preference = Preference.new(preference_params)
    @preference.save!

    redirect_to :action => 'index'
  end

  def update
    @preference = Preference.find(params[:id])
    @preference.attributes = preference_params
    @preference.save!

    redirect_to :action => 'index'
  end

  private

  def preference_params
    permitted = [:theme, :use_todo, :use_two_factor_authentication, :default_priority]
    params.require(:preference).permit(permitted).merge(:user_id => current_user.id)
  end

end
