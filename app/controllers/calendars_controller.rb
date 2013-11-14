# coding: UTF-8

class CalendarsController < ApplicationController

  def index
    @calendars = Calendar.where(:user_id => current_user).not_deleted.order(:title)
  end

  def show
    @calendar = Calendar.find(params[:id])
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
