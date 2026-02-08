def feed_of(user_id)
  Feed.where(user_id: user_id).first
end

def feed_params
  ret = {}
  ret[:title] = 'Test Feed'
  ret[:display_count] = 20
  ret[:feed_url] = 'https://feed.example.com'
  ret
end