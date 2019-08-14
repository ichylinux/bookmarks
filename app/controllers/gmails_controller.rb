class GmailsController < ApplicationController

  def index
    @gmails = current_user.gmails
  end

  def show
    @gmail = current_user.gmails.find(params[:id])
    
    render layout: false
  end

  def new
    @gmail = current_user.gmails.build(title: 'Gmail')
  end

  def create
    @gmail = current_user.gmails.build(gmail_params)

    @gmail.transaction do
      @gmail.save!
    end

    redirect_to action: 'index'
  end

  def edit
    @gmail = current_user.gmails.find(params[:id])
  end

  def update
    @gmail = current_user.gmails.find(params[:id])
    @gmail.attributes = gmail_params

    @gmail.transaction do
      @gmail.save!
    end

    redirect_to action: 'index'
  end

  def destroy
    @gmail = current_user.gmails.find(params[:id])

    @gmail.transaction do
      @gmail.destroy_logically!
    end

    redirect_to action: 'index'
  end

  private

  def gmail_params
    params.require(:gmail).permit(:title, :labels, :display_count)
  end

end
