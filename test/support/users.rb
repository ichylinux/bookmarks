def user
  assert @_user ||= User.first
  @_user
end

def user_without_calendar
  return @_user_without_calendar if @_user_without_calendar

  sql = SqlBuilder.new
  sql.append('not exists (')
  sql.append('  select 1 from calendars c where c.user_id = users.id and c.deleted = ?', false)
  sql.append(')')

  assert @_user_without_calendar = User.where(sql.to_a).first
  @_user_without_calendar
end

def user_without_two_factor_authentication
  unless @_user_without_two_factor_authentication
    sql = SqlBuilder.new
    sql.append('not exists (')
    sql.append('  select 1 from preferences p')
    sql.append('  where p.user_id = users.id')
    sql.append('    and p.use_two_factor_authentication = ?', true)
    sql.append(')')

    assert @_user_without_two_factor_authentication = User.where(sql.to_a).first
  end
  
  @_user_without_two_factor_authentication
end