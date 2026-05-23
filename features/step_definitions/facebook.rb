Given 'サインインページを開く' do
  visit '/users/sign_in'
end

When 'サインアップページを開く' do
  visit '/users/sign_up'
end

Then 'Facebookサインインボタンが表示される' do
  assert has_selector?('.auth-oauth-btn--facebook'), 'Facebookサインインボタンが見つかりません'
end
