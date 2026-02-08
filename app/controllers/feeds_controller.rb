class FeedsController < ApplicationController
  before_action :preload_feed, only: ['show', 'edit', 'update', 'destroy']

  def index
    @feeds = Feed.where(user_id: current_user.id).not_deleted
  end

  def show
    if @feed.feed?
      render layout: !request.xhr?
    else
      render plain: @feed.status, status: @feed.status
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

    redirect_to action: 'index'
  end

  def edit
  end

  def update
    @feed.attributes = feed_params

    @feed.transaction do
      @feed.save!
    end

    redirect_to action: 'index'
  end

  def destroy
    @feed.transaction do
      @feed.destroy_logically!
    end

    redirect_to action: 'index'
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

  def preload_feed
    @feed = Feed.find(params[:id])

    unless @feed.readable_by?(current_user)
      head :not_found and return
    end
  end

  def feed_params
    ret = params.require(:feed).permit(:title, :feed_url, :display_count)

    ret.merge!(user_id: current_user.id)

    ret
  end

end
