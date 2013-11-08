# coding: UTF-8

class BookmarkGadget
  
  def initialize(bookmarks)
    @bookmarks = bookmarks
  end

  def gadget_id
    'bookmark'
  end

  def title
    'Bookmark'
  end
  
  def entries
    @bookmarks
  end

end