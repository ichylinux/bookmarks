# coding: UTF-8

class WelcomeController < ApplicationController

  def index
    @portal = Portal.new(current_user)
  end

  def save_state
    render :nothing => true
  end

end
