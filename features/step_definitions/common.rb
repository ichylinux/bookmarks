もし /^再度ログインし直すと、ワンタイムパスワードを要求されます。$/ do
  with_capture do
    click_on current_user.email
    click_on 'ログアウト'
    assert_equal '/users/sign_in', current_path
  end

  with_capture do
    fill_in 'Eメール', :with => current_user.email
    fill_in 'パスワード', :with => 'testtest'
  end
  click_on 'ログイン'

  with_capture do
    assert has_selector?('form[action="/users/two_factor_authentication"]')
  end
end
