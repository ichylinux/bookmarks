class BookmarksController < ApplicationController
  
  def index
    @bookmarks = Bookmark.where(:user_id => current_user).not_deleted.order(:title)
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
      @bookmark.attributes = bookmark_params
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

  def new_import
    @bookmark_import_form = BookmarkImportForm.new
  end

  def confirm_import
    @bookmark_import_form = BookmarkImportForm.new(params[:bookmark_import_form])

    doc = Nokogiri::XML(@bookmark_import_form.bookmark_file.open)
    @bookmark_import_form.bookmarks = doc.css('A').map { |a| Bookmark.new(:title => a.text, :url => a['HREF']) }
  end

  def import
    @bookmark_import_form = BookmarkImportForm.new(params[:bookmark_import_form])
    
    Bookmark.transaction do
      @bookmark_import_form.bookmarks.each do |b|
        b.user = current_user
        b.save!
      end
    end
    
    redirect_to :action => 'index'
  end

  private

  def bookmark_params
    params.require(:bookmark).permit(:user_id, :title, :url)
  end
end
