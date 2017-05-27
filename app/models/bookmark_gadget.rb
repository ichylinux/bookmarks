class BookmarkGadget
  include Gadget
  
  def title
    'Bookmark'
  end
  
  def entries
    @entries ||= Bookmark.where(user_id: user.id, deleted: false).order(:title)
  end

end