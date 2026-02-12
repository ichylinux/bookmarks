class BookmarksController < ApplicationController
  before_action :preload_bookmark, only: ['show', 'edit', 'update', 'destroy']

  def index
    @parent_id = params[:parent_id]
    @parent = @parent_id.present? ? Bookmark.find_by(id: @parent_id, user_id: current_user.id) : nil

    @bookmarks = Bookmark.where(user_id: current_user.id, parent_id: @parent_id, deleted: false).order(:title)

  end

  def show
  end

  def new
    @bookmark = Bookmark.new
    @parent_id = params[:parent_id]
    @bookmark.parent_id = @parent_id if @parent_id.present?
    # 新規作成時はすべてのフォルダを利用可能
    @available_folders = Bookmark.where(user_id: current_user.id, deleted: false).folders.order(:title)
  end

  def create
    @bookmark = Bookmark.new(bookmark_params)
    
    @bookmark.transaction do
      @bookmark.save!
    end
    
    redirect_to action: 'index', parent_id: @bookmark.parent_id
  end

  def edit
    # 編集時に循環参照を防ぐため、利用可能なフォルダリストを準備
    @available_folders = Bookmark.where(user_id: current_user.id, deleted: false)
                                  .folders
                                  .where.not(id: @bookmark.id)
                                  .order(:title)
  end
  
  def update
    @bookmark.attributes = bookmark_params
    
    @bookmark.transaction do
      @bookmark.save!
    end
    
    redirect_to action: 'index', parent_id: @bookmark.parent_id
  end

  def destroy
    parent_id = @bookmark.parent_id
    
    @bookmark.transaction do
      @bookmark.destroy_logically!
    end
    
    redirect_to action: 'index', parent_id: parent_id
  end

  private

  def preload_bookmark
    @bookmark = Bookmark.find(params[:id])

    unless @bookmark.readable_by?(current_user)
      head :not_found and return
    end
  end

  def bookmark_params
    ret = params.require(:bookmark).permit(:title, :url, :parent_id)
    
    # urlが空文字列の場合はnilに変換（フォルダの場合）
    ret[:url] = nil if ret[:url].blank?

    case action_name
    when 'create'
      ret = ret.merge(user_id: current_user.id)
    end
    
    ret
  end
end
