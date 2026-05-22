もし /^シンプルテーマでサインインします。$/ do
  Note.where(user_id: user.id).delete_all
  sign_in user
  visit '/preferences'
  select 'シンプル', from: 'テーマ'
  click_on '保存'
  assert has_text?('設定を保存しました。')
end
