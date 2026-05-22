もし /^最初のXガジェットに "([^"]*)" が表示される$/ do |text|
  acc = XAccount.where(user_id: user.id).order(:id).last
  assert acc, 'Xアカウントが作成されているはずです'
  assert_selector("##{acc.gadget_id}", text: text, wait: 15)
end

もし /^Xアカウント一覧ページを開きます。$/ do
  visit x_accounts_path
end

もし /^ハンドル入力欄に "([^"]*)" と入力します。$/ do |handle|
  fill_in placeholder: '@handle', with: handle
end

もし /^追加ボタンを押します。$/ do
  click_button '追加'
end

もし /^"([^"]*)" がXアカウント一覧に表示される$/ do |handle|
  assert_text handle, wait: 10
end

もし /^フォロー一覧を更新ボタンを押します。$/ do
  click_button 'フォロー一覧を更新'
end

もし /^ユーザーが見つからないエラーメッセージが表示される$/ do
  assert_text 'データが見つかりませんでした。', wait: 5
end
