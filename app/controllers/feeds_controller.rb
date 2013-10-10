# coding: UTF-8

class FeedsController < ApplicationController

  def index
    @feeds = Feed.where(:user_id => current_user.id).not_deleted
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

  def destroy
    @feed = Feed.find(params[:id])
    @feed.destroy_logically!

    redirect_to :action => 'index'
  end

end
