def count_visited_link_queries
  count = 0
  callback = ->(*, payload) { count += 1 if payload[:sql].to_s.include?('visited_links') }
  ActiveSupport::Notifications.subscribed(callback, 'sql.active_record') do
    yield
  end
  count
end
