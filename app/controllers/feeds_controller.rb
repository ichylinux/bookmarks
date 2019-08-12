class FeedsController < ApplicationController

  def index
    @feeds = Feed.where(:user_id => current_user.id).not_deleted
  end

  def show
    @feed = Feed.find(params[:id])
    
    unless @feed.readable_by?(current_user)
      head :not_found and return
    end

    if @feed.feed?
      render :layout => ! request.xhr?
    else
      render :text => @feed.status, :status => @feed.status
    end
  end

  def new
    @feed = Feed.new
  end

  def create
    @feed = Feed.new(feed_params)

    @feed.transaction do
      @feed.save!
    end

    redirect_to :action => 'index'
  end

  def edit
    @feed = Feed.find(params[:id])
  end

  def update
    @feed = Feed.find(params[:id])
    @feed.attributes = feed_params

    @feed.transaction do
      @feed.save!
    end

    redirect_to :action => 'index'
  end

  def destroy
    @feed = Feed.find(params[:id])

    @feed.transaction do
      @feed.destroy_logically!
    end

    redirect_to :action => 'index'
  end

  def get_feed_title
    @feed = Feed.new(feed_params)
    if @feed.feed?
      render plain: @feed.feed.title
    else
      head :ok
    end
  end

  private

  def feed_params
    ret = params.require(:feed).permit(:user_id, :title, :feed_url, :display_count,
          :auth_user, :auth_password, :auth_url)

    ret.merge!(user_id: current_user.id)

    ret
  end

end
