# coding: UTF-8

class WelcomeController < ApplicationController

  def index
    @portal = Portal.new(current_user)
  end

  def save_state
    ActiveRecord::Base.transaction do
      Portal.new(current_user).update_layout(params[:portal])
    end

    render :nothing => true
  end

end
