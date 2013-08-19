# coding: UTF-8

class WelcomeController < ApplicationController
  before_filter :authenticate_user!
  
  def index
    
  end

end
