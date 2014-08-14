def bookmark(user)
  @_bookmarks ||= {}
  assert @_bookmarks[user.id] ||= Calendar.where(:user_id => user.id).first
  @_bookmarks[user.id]
end

def valid_bookmark_params(user)
  {
    :user_id => user.id,
    :title => 'ブックマーク',
    :url => 'www.example.com'
  }
end

def invalid_bookmark_params(user)
  {
    :user_id => user.id,
    :title => '',
    :url => 'www.example.com'
  }
end
