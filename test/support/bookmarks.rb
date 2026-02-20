def bookmark(user)
  @_bookmarks ||= {}
  assert @_bookmarks[user.id] ||= Bookmark.where(user_id: user.id).not_deleted.first
  @_bookmarks[user.id]
end

def bookmark_params(user)
  {
    title: 'ブックマーク',
    url: 'www.example.com'
  }
end

def folder_params(user)
  {
    title: 'テストフォルダ',
    url: nil,
    parent_id: nil
  }
end

def bookmark_in_folder_params(user, folder)
  {
    title: 'フォルダ内ブックマーク',
    url: 'www.example.com',
    parent_id: folder.id
  }
end

def invalid_bookmark_params(user)
  {
    user_id: user.id,
    title: '',
    url: 'www.example.com'
  }
end
