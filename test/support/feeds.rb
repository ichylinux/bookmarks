def feed_of(user_id)
  Feed.where(:user_id => user_id).first
end