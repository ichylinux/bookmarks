もし /^再度ログインし直すと、ワンタイムパスワードを要求されます。$/ do
  click_on current_user.email
  click_on 'ログアウト'
  assert_equal '/users/sign_in', current_path
  
  fill_in 'Email', :with => current_user.email
  fill_in 'Password', :with => 'testtest'
  capture
  click_on 'Log in'

  begin
    assert has_selector?('form[action="/users/two_factor_authentication"]')
  ensure
    capture
  end
end
