もし /^最初のXガジェットに "([^"]*)" が表示される$/ do |text|
  acc = XAccount.where(user_id: user.id).order(:id).last
  assert acc, 'Xアカウントが作成されているはずです'
  assert_selector("##{acc.gadget_id}", text: text, wait: 15)
end
