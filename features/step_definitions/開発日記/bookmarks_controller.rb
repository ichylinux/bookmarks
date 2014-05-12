# coding: UTF-8

class BookmarksController < ApplicationController

  def index
    @bookmarks = Bookmark.not_deleted
  end

  def show
    @bookmark = Bookmark.find(params[:id])
  end

  def new
    @bookmark = Bookmark.new
  end

  def create
    @bookmark = Bookmark.new(params[:bookmark])
    
    begin
      @bookmark.transaction do
        @bookmark.save!
      end

      redirect_to :action => 'show', :id => @bookmark.id

    rescue ActiveRecord::RecordInvalid => e
      render :new
    end
  end

  def edit
    @bookmark = Bookmark.find(params[:id])
  end

  def update
    @bookmark = Bookmark.find(params[:id])
    
    begin
      @bookmark.transaction do
        @bookmark.attributes = params[:bookmark]
        @bookmark.save!
      end

      redirect_to :action => 'show', :id => @bookmark.id

    rescue ActiveRecord::RecordInvalid => e
      render :edit
    end
  end

  def destroy
    @bookmark = Bookmark.find(params[:id])
    
    @bookmark.transaction do
      @bookmark.destroy_logically!
    end
    
    redirect_to :action => 'index'
  end

end
