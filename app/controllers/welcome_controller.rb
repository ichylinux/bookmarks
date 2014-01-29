# coding: UTF-8

class WelcomeController < ApplicationController

  def index
    @portal = current_user.portals.first
  end

  def save_state
    ActiveRecord::Base.transaction do
      current_user.portals.first.update_layout(params[:portal])
    end

    render :nothing => true
  end

end
