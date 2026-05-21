# frozen_string_literal: true

もし /^ユーザー一覧ページを開きます。$/ do
  visit admin_users_path
  capture
end

ならば /^ユーザーテーブルが表示される$/ do
  assert page.has_css?('.admin-users__table'), 'ユーザーテーブルが表示されるはずです'
  assert page.has_content?('user@example.com'), '管理者ユーザーの行が表示されるはずです'
end
