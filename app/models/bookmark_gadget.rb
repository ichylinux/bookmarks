class BookmarkGadget
  include Gadget
  
  def title
    'Bookmark'
  end
  
  def entries
    # フォルダを先頭にし、その後ブックマークをタイトル順で取得
    @all_entries ||= Bookmark.where(user_id: user.id, parent_id: nil, deleted: false).order(Arel.sql('url IS NULL DESC'), :title)
  end

end