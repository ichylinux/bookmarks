# coding: UTF-8

class BookmarksController < ApplicationController
  
  def index
    @bookmarks = Bookmark.where(:user_id => current_user).not_deleted
  end

  def show
    @bookmark = Bookmark.find(params[:id])
  end

  def new
    @bookmark = Bookmark.new
  end

  def create
    @bookmark = Bookmark.new(params[:bookmark])
    
    @bookmark.transaction do
      @bookmark.user = current_user
      @bookmark.save!
    end
    
    redirect_to :action => 'index'
  end

  def edit
    @bookmark = Bookmark.find(params[:id])
  end
  
  def update
    @bookmark = Bookmark.find(params[:id])
    
    @bookmark.transaction do
      @bookmark.attributes = params[:bookmark]
      @bookmark.save!
    end
    
    redirect_to :action => 'show', :id => @bookmark
  end

  def destroy
    @bookmark = Bookmark.find(params[:id])
    
    @bookmark.transaction do
      @bookmark.destroy_logically!
    end
    
    redirect_to :action => 'index'
  end
end
