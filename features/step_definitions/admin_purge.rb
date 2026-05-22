# frozen_string_literal: true

PURGE_E2E_EMAIL = 'purge_e2e_test@example.com'

ならば /^完全削除対象のテストユーザーが一覧に表示される$/ do
  u = User.find_by!(email: PURGE_E2E_EMAIL)
  assert page.has_content?(PURGE_E2E_EMAIL), 'テストユーザーのメールが一覧に表示されるはずです'
  assert page.has_link?(
    I18n.t('admin.users.index.purge_button', locale: :ja),
    href: confirm_purge_admin_user_path(u)
  ), '完全削除リンクが表示されるはずです'
end

もし /^完全削除ボタンをクリックします。$/ do
  u = User.find_by!(email: PURGE_E2E_EMAIL)
  click_link I18n.t('admin.users.index.purge_button', locale: :ja), href: confirm_purge_admin_user_path(u)
  capture
end

ならば /^完全削除の確認ページが表示される$/ do
  assert page.has_content?(I18n.t('admin.users.confirm_purge.title', locale: :ja)),
         '確認ページの見出しが表示されるはずです'
  assert page.has_content?(PURGE_E2E_EMAIL), '対象ユーザーのメールが確認ページに表示されるはずです'
end

もし /^完全削除を実行します。$/ do
  click_button I18n.t('admin.users.confirm_purge.submit', locale: :ja)
  capture
end

ならば /^テストユーザーが一覧から消える$/ do
  assert_equal admin_users_path, page.current_path
  assert_not page.has_content?(PURGE_E2E_EMAIL), '削除後はテストユーザーが一覧に表示されないはずです'
  assert_not User.exists?(email: PURGE_E2E_EMAIL), 'ユーザー行がDBから削除されているはずです'
end
