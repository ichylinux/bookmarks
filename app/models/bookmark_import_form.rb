class BookmarkImportForm < Daddy::Model

  def bookmarks
    unless @bookmarks
      @bookmarks = []
    
      self.bookmark.values.each do |b|
        @bookmarks << Bookmark.new(:title => b[:title], :url => b[:url])
      end
    end
    
    @bookmarks
  end

  def bookmarks=(bookmarks)
    @bookmarks = bookmarks
  end
end