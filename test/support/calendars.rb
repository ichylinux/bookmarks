def calendar(user)
  @_calendars ||= {}
  assert @_calendars[user.id] ||= Calendar.where(:user_id => user.id).first
  @_calendars[user.id]
end

def valid_calendar_params(user)
  {
    :user_id => user.id,
    :title => 'カレンダータイトル'
  }
end