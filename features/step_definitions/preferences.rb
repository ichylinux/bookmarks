もし /^設定画面を表示します。$/ do
  sign_in user

  begin
    visit '/preferences'
    assert has_selector?('form.edit_user')
  ensure
    capture
  end
end

もし /^ポータル列数を4列に変更して保存します。$/ do
  select '4列', from: 'ポータル列数'
  click_on '保存'
end

ならば /^設定画面を再表示すると4列が選択されています。$/ do
  visit '/preferences'
  assert has_select?('ポータル列数', selected: '4列'),
    'ポータル列数が4列として選択されているはずです'
  capture
end
