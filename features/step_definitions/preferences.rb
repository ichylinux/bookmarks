もし /^設定画面を表示します。$/ do
  sign_in user_without_two_factor_authentication

  begin
    visit '/preferences'
    assert has_selector?('form.edit_user')
  ensure
    capture
  end
end

もし /^２段階認証を使用する にチェックを入れます。$/ do
  begin
    check '２段階認証を使用する'
    click_on '保存'
  ensure
    capture
  end
end
