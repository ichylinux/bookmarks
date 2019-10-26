class BookmarksController < ApplicationController
  
  def index
    @bookmarks = Bookmark.where(user_id: current_user).not_deleted.order(:title)
  end

  def show
    @bookmark = Bookmark.find(params[:id])
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
    @bookmark = Bookmark.find(params[:id])
  end
  
  def update
    @bookmark = Bookmark.find(params[:id])
    @bookmark.attributes = bookmark_params
    
    @bookmark.transaction do
      @bookmark.save!
    end
    
    redirect_to action: 'show', id: @bookmark
  end

  def destroy
    @bookmark = Bookmark.find(params[:id])
    
    @bookmark.transaction do
      @bookmark.destroy_logically!
    end
    
    redirect_to action: 'index'
  end

  private

  def bookmark_params
    ret = params.require(:bookmark).permit(:title, :url)

    case action_name
    when 'create'
      ret = ret.merge(user_id: current_user.id)
    end
    
    ret
  end
end
