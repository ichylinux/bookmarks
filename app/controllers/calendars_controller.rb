# coding: UTF-8

class CalendarsController < ApplicationController

  def index
    c = Calendar.where(:user_id => current_user).not_deleted.first
    if c
      redirect_to :action => 'show', :id => c.id
    else
      redirect_to :action => 'new'
    end
  end

  def show
    @calendar = Calendar.find(params[:id])
  end

  def get_gadget
    @calendar = Calendar.find(params[:id])
    @calendar.display_date = Date.parse(params[:display_date])
    render :layout => false
  end

  def new
    @calendar = Calendar.new(:user_id => current_user.id)
  end

  def create
    @calendar = Calendar.new(params[:calendar])
    
    begin
      @calendar.transaction do
        @calendar.save!
      end

      redirect_to :action => 'show', :id => @calendar.id

    rescue ActiveRecord::RecordInvalid => e
      render :new
    end
  end

  def edit
    @calendar = Calendar.find(params[:id])
  end

  def update
    @calendar = Calendar.find(params[:id])
    
    begin
      @calendar.transaction do
        @calendar.attributes = params[:calendar]
        @calendar.save!
      end

      redirect_to :action => 'show', :id => @calendar.id

    rescue ActiveRecord::RecordInvalid => e
      render :edit
    end
  end

  def destroy
    @calendar = Calendar.find(params[:id])
    
    @calendar.transaction do
      @calendar.destroy_logically!
    end
    
    redirect_to :action => 'index'
  end

end
