require 'uri'

class BookmarksController < ApplicationController
  before_action :preload_bookmark, only: ['show', 'edit', 'update', 'destroy']

  def index
    @parent_id = params[:parent_id]
    @parent = @parent_id.present? ? Bookmark.find_by(id: @parent_id, user_id: current_user.id) : nil

    # フォルダを先に、その後ブックマークをタイトル順で表示
    @bookmarks = Bookmark.where(user_id: current_user.id, parent_id: @parent_id, deleted: false).order(Arel.sql('url IS NULL DESC'), :title)

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
    
    if params[:return_to] == 'dashboard'
      redirect_to root_path
    else
      redirect_to action: 'index', parent_id: @bookmark.parent_id
    end
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

  def fetch_title
    raw_url = params[:url].to_s.strip
    raise ArgumentError, 'blank url' if raw_url.blank?
    url = safe_fetch_title_url!(raw_url)

    conn = Faraday.new do |f|
      f.options.timeout      = 5
      f.options.open_timeout = 5
      f.response :follow_redirects
    end

    response = conn.get(url)
    title = Nokogiri::HTML(response.body).at('title')&.text&.strip
    raise 'no title' if title.blank?

    render plain: title
  rescue StandardError
    head :ok
  end

  private

  def safe_fetch_title_url!(raw_url)
    uri = URI.parse(raw_url)
    raise ArgumentError, 'invalid url' unless uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)
    raise ArgumentError, 'invalid host' if uri.host.blank?

    uri.to_s
  rescue URI::InvalidURIError
    raise ArgumentError, 'invalid url'
  end

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
