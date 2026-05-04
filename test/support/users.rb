def user
  assert @_user ||= User.first
  @_user
end
