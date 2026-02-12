class BookmarkGadget
  include Gadget
  
  def title
    'Bookmark'
  end
  
  def entries
    # フォルダとブックマークを区別せず、タイトル順で取得
    @all_entries ||= Bookmark.where(user_id: user.id, parent_id: nil, deleted: false).order(:title)
  end

end