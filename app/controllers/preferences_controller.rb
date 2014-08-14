class PreferencesController < ApplicationController

  def index
    @preference = current_user.preference || Preference.new(:user_id => current_user.id)
  end

  def create
    @preference = Preference.new(preference_params)
    @preference.user_id = current_user.id
    @preference.save!

    redirect_to :action => 'index'
  end

  def update
    @preference = Preference.find(params[:id])
    @preference.user_id = current_user.id
    @preference.attributes = preference_params
    @preference.save!
    
    redirect_to :action => 'index'
  end

  private

  def preference_params
    params.require(:preference).permit(:user_id, :theme, :use_todo)
  end

end
