class BookmarksController < ApplicationController
  before_action :preload_bookmark, only: ['show', 'edit', 'update', 'destroy']

  def index
    @bookmarks = Bookmark.where(user_id: current_user).not_deleted.order(:title)
  end

  def show
  end

  def new
    @bookmark = Bookmark.new
  end

  def create
    @bookmark = Bookmark.new(bookmark_params)
    
    @bookmark.transaction do
      @bookmark.save!
    end
    
    redirect_to action: 'index'
  end

  def edit
  end
  
  def update
    @bookmark.attributes = bookmark_params
    
    @bookmark.transaction do
      @bookmark.save!
    end
    
    redirect_to action: 'show', id: @bookmark
  end

  def destroy
    @bookmark.transaction do
      @bookmark.destroy_logically!
    end
    
    redirect_to action: 'index'
  end

  private

  def preload_bookmark
    @bookmark = Bookmark.find(params[:id])

    unless @bookmark.readable_by?(current_user)
      head :not_found and return
    end
  end

  def bookmark_params
    ret = params.require(:bookmark).permit(:title, :url)

    case action_name
    when 'create'
      ret = ret.merge(user_id: current_user.id)
    end
    
    ret
  end
end
