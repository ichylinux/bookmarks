class CalendarsController < ApplicationController
  before_filter :load_calendar, :except => ['index', 'new', 'create']

  def index
    @calendar = Calendar.where(:user_id => current_user).not_deleted.first

    if @calendar
      redirect_to :action => 'show', :id => @calendar.id
    else
      redirect_to :action => 'new'
    end
  end

  def show
  end

  def get_gadget
    @calendar.display_date = Date.parse(params[:display_date])
    render :layout => false
  end

  def new
    @calendar = Calendar.new(:user_id => current_user.id)
  end

  def create
    @calendar = Calendar.new(calendar_params)
    
    begin
      @calendar.transaction do
        @calendar.save!
      end

      redirect_to @calendar

    rescue ActiveRecord::RecordInvalid => e
      render :new
    end
  end

  def edit
  end

  def update
    begin
      @calendar.transaction do
        @calendar.attributes = calendar_params
        @calendar.save!
      end

      redirect_to @calendar

    rescue ActiveRecord::RecordInvalid => e
      render :edit
    end
  end

  def destroy
    @calendar.transaction do
      @calendar.destroy_logically!
    end
    
    redirect_to :action => 'index'
  end

  private

  def load_calendar
    @calendar = Calendar.find(params[:id])

    unless @calendar.readable_by?(current_user)
      render :nothing => true, :status => :not_found
    end
  end

  def calendar_params
    params.require(:calendar).permit(:user_id, :title, :show_weather)
  end

end
