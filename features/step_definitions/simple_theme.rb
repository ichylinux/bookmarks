もし /^シンプルテーマでサインインします。$/ do
  Note.where(user_id: user.id).delete_all
  sign_in user
  visit '/preferences'
  assert has_selector?('form.preferences-form')
  select_option_value "#{PreferencesReset::PREF}[theme]", 'simple'
  find('form.preferences-form input[type="submit"]', match: :first).click
  assert has_text?('設定を保存しました。')
end
