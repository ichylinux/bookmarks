もし /^user3としてログインして設定画面を開きます。$/ do
  @deletion_user = User.find(3)
  sign_in @deletion_user
  visit '/preferences'
  assert_selector 'form.preferences-form'
end

もし /^アカウント削除ページへ進みます。$/ do
  visit '/account_deletion/new'
  assert_selector 'form.account-deletions-form'
  assert_selector 'input[name="confirmation"]'
end

もし /^確認のためDELETEと入力してアカウントを削除します。$/ do
  fill_in 'confirmation', with: 'DELETE'
  click_button I18n.t('account_deletions.new.submit', locale: :ja)
  while page.driver.response.redirect?
    page.driver.follow_redirect!
  end
end

ならば /^ログアウトされホーム画面が表示されます。$/ do
  @deletion_user.reload
  assert @deletion_user.deleted?, 'user should be soft-deleted'
  assert_text I18n.t('landing.hero.eyebrow', locale: :ja)
end

ならば /^削除したアカウントではログインできません。$/ do
  Capybara.reset_sessions!
  @_current_user = nil

  visit '/users/sign_in'
  fill_in 'user[email]', with: 'user3@example.com'
  fill_in 'user[password]', with: 'testtest'
  find('input[type="submit"], button[type="submit"]', match: :first).click

  visit '/preferences'
  assert_equal new_user_session_path, current_path
end
