もし /^設定画面を表示します。$/ do
  sign_in user

  begin
    visit '/preferences'
    assert has_selector?('form.edit_user')
  ensure
    capture
  end
end
