# coding: UTF-8

class CalendarsController < ApplicationController
  before_filter :load_calendar

  def index
    if @calendar
      redirect_to :action => 'show', :id => @calendar.id
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

  private

  def load_calendar
    if action_name == 'index'
      @calendar = Calendar.where(:user_id => current_user).not_deleted.first
    else
      @calendar = Calendar.find(params[:id])
      unless @calendar.readable_by?(current_user)
        render :nothing => true, :status => :not_found
        return false
      end
    end
    
    true
  end

end
