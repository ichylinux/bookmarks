def user
  @_user ||= User.first
end

def user_without_calendar
  return @_user_without_calendar if @_user_without_calendar

  sql = SqlBuilder.new
  sql.append('not exists (')
  sql.append('  select 1 from calendars c where c.user_id = users.id')
  sql.append(')')

  assert @_user_without_calendar = User.where(sql.to_a).first
  @_user_without_calendar
end