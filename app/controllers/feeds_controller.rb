class FeedsController < ApplicationController
  before_action :preload_feed, only: ['show', 'edit', 'update', 'destroy']
  before_action :assign_visited_urls, only: [:show]

  def index
    @feeds = Feed.where(user_id: current_user.id).not_deleted
  end

  def show
    if @feed.feed?
      render layout: false
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

    if params[:return_to] == 'dashboard'
      if request.xhr?
        head :ok
      else
        redirect_to root_path
      end
    else
      redirect_to action: 'index'
    end
  rescue ActiveRecord::RecordInvalid
    if params[:return_to] == 'dashboard' && request.xhr?
      render plain: @feed.errors.full_messages.to_sentence, status: :unprocessable_entity
    else
      raise
    end
  end

  def destroy
    @feed.transaction do
      @feed.destroy_logically!
    end

    redirect_to action: 'index'
  end

  def fetch_title
    feed_url = params[:feed_url].to_s.strip
    raise ArgumentError, 'blank feed_url' if feed_url.blank?

    @feed = Feed.new(user_id: current_user.id, feed_url: feed_url)
    if @feed.feed?
      render plain: @feed.feed.title
    else
      head :ok
    end
  rescue StandardError
    head :ok
  end

  private

  def preload_feed
    @feed = Feed.find(params[:id])

    unless @feed.readable_by?(current_user)
      head :not_found and return
    end
  end

  def assign_visited_urls
    entry_urls = @feed.entries.map { |e| VisitedLink.normalize_url(e.url) }.reject(&:blank?)
    @visited_urls = VisitedLink.where(user_id: current_user.id, url: entry_urls).pluck(:url).to_set
  end

  def feed_params
    ret = params.require(:feed).permit(:title, :feed_url, :display_count)

    ret.merge!(user_id: current_user.id)

    ret
  end

end
