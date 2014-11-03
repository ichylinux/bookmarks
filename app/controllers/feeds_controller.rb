class FeedsController < ApplicationController

  def index
    @feeds = Feed.where(:user_id => current_user.id).not_deleted
  end

  def show
    @feed = Feed.find(params[:id])
    
    unless @feed.readable_by?(current_user)
      render :nothing => true, :status => :not_found and return
    end

    render :layout => ! request.xhr?
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
      render :text => @feed.feed.title
    else
      render :nothing => true
    end
  end

  private

  def feed_params
    params[:feed][:user_id] = current_user.id

    params.require(:feed).permit(
        :user_id, :title, :feed_url, :display_count,
        :auth_user, :auth_encrypted_password, :auth_salt, :auth_url)
  end

end
