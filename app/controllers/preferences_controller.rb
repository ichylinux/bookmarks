# coding: UTF-8

class PreferencesController < ApplicationController

  def index
    @preference = current_user.preference || Preference.new(:user_id => current_user.id)
  end

  def create
    @preference = Preference.new(params[:preference])
    @preference.user_id = current_user.id
    @preference.save!

    redirect_to :action => 'index'
  end

  def update
    @preference = Preference.find(params[:id])
    @preference.user_id = current_user.id
    @preference.attributes = params[:preference]
    @preference.save!
    
    redirect_to :action => 'index'
  end
end
