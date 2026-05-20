# frozen_string_literal: true

もし /^X API 利用状況のデータが存在する$/ do
  u2 = User.find_by!(email: 'user2@example.com')
  XApiCall.record!(user_id: u2.id, endpoint: 'fetch_following', success: true)
end

もし /^管理者としてサインインします。$/ do
  admin = User.find_by!(email: 'user@example.com')
  admin.preference.update!(theme: 'modern')
  sign_in admin
end

もし /^一般ユーザーとしてサインインします。$/ do
  u = User.find_by!(email: 'user2@example.com')
  u.update_columns(admin: false)
  u.preference.update!(theme: 'modern')
  sign_in u
end

もし /^X API 利用状況ページを開きます。$/ do
  visit admin_x_api_usages_path
  capture
end

ならば /^利用状況テーブルに user2@example\.com の行が表示される$/ do
  assert page.has_css?('.admin-x-api-usages__table'), '利用状況テーブルが表示されるはずです'
  assert page.has_content?('user2@example.com'), 'user2 の行が表示されるはずです'
end

ならば /^X API 利用状況ページにアクセスすると 404 になる$/ do
  visit admin_x_api_usages_path
  assert_equal 404, page.status_code
end
