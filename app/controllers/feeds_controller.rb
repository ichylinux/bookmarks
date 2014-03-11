# coding: UTF-8

class FeedsController < ApplicationController

  def index
    @feeds = Feed.where(:user_id => current_user.id).not_deleted
  end

  def show
    @feed = Feed.find(params[:id])
    
    unless @feed.readable_by?(current_user)
      render :nothing => true, :status => :not_found
      return
    end

    render :layout => ! request.xhr?
  end

  def new
    @feed = Feed.new
  end

  def create
    @feed = Feed.new(params[:feed])
    @feed.user_id = current_user.id
    @feed.save!

    redirect_to :action => 'index'
  end

  def edit
    @feed = Feed.find(params[:id])
  end

  def update
    @feed = Feed.find(params[:id])
    @feed.attributes = params[:feed]
    @feed.save!
    
    redirect_to :action => 'index'
  end

  def destroy
    @feed = Feed.find(params[:id])
    @feed.destroy_logically!

    redirect_to :action => 'index'
  end

  def get_feed_title
    @feed = Feed.new(params[:feed])
    if @feed.feed?
      render :text => @feed.feed.title
    else
      render :nothing => true
    end
  end
end
