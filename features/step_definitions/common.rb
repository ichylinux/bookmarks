もし /^再度ログインし直すと、ワンタイムパスワードを要求されます。$/ do
  with_capture do
    click_on current_user.email
    click_on 'ログアウト'
    assert_equal '/users/sign_in', current_path
  end

  with_capture do
    fill_in 'Email', :with => current_user.email
    fill_in 'Password', :with => 'testtest'
  end
  click_on 'Log in'

  with_capture do
    assert has_selector?('form[action="/users/two_factor_authentication"]')
  end
end
