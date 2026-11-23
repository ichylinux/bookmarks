NOTE_SCOPE = '#notes-page .note-gadget'

もし /^シンプルテーマでノートを有効にしてサインインします。$/ do
  Note.where(user_id: user.id).delete_all
  sign_in user
  visit '/preferences'
  select 'シンプル', from: 'テーマ'
  check 'ノートを表示する'
  click_on '保存'
  assert has_text?('設定を保存しました。')
end

もし /^モダンテーマでノートを有効にしてサインインします。$/ do
  Note.where(user_id: user.id).delete_all
  sign_in user
  visit '/preferences'
  select 'モダン', from: 'テーマ'
  check 'ノートを表示する'
  click_on '保存'
  assert has_text?('設定を保存しました。')
end

もし /^ヘッダーのノートアイコンからノート画面を開きます。$/ do
  visit root_path
  find('a.head-note-btn[aria-label="ノート"]', match: :first).click
  assert has_selector?('#notes-page .note-gadget')
  assert_equal notes_path, current_path
end

もし /^ノートページを開きます。$/ do
  visit notes_path
  assert has_selector?('#notes-page .note-gadget')
  capture
end

もし /^メモに (.*?) と入力してメモを保存します。$/ do |body|
  @note_body = body
  within NOTE_SCOPE do
    find('textarea[name="note[body]"]').set(body)
  end
  click_on 'メモを保存'
  assert_equal notes_path, current_path
end

もし /^ノートページに (.*?) が先頭表示されます。$/ do |body|
  assert_equal @note_body, body if @note_body
  within NOTE_SCOPE do
    first_note_body = find('.note-item:first-child .note-body').text
    assert_equal body, first_note_body
  end
end

もし /^先頭メモを編集表示にします。$/ do
  within "#{NOTE_SCOPE} .note-item:first-child" do
    find('.note-item-display').double_click
    assert has_no_selector?('.note-item-edit-form[hidden]', wait: 3)
    assert has_button?('キャンセル')
  end
end

もし /^先頭メモの編集欄に (.*?) と入力します。$/ do |body|
  @editing_note_body = body
  within "#{NOTE_SCOPE} .note-item:first-child.note-item--editing" do
    find('textarea[name="note[body]"]').set(body)
  end
end

もし /^先頭メモの編集表示をキャンセルします。$/ do
  within "#{NOTE_SCOPE} .note-item:first-child.note-item--editing" do
    click_button 'キャンセル'
  end
  assert has_no_selector?("#{NOTE_SCOPE} .note-item:first-child.note-item--editing", wait: 3)
end

もし /^ノートページの先頭メモ本文は (.*?) のままです。$/ do |body|
  assert_not_equal @editing_note_body, body
  within NOTE_SCOPE do
    first_note_body = find('.note-item:first-child .note-body').text
    assert_equal body, first_note_body
  end
end
