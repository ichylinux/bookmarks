require 'uri'

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
  assert has_selector?('#notes-tab-panel')
  uri = URI.parse(current_url)
  tab = Rack::Utils.parse_query(uri.query)['tab']
  assert_equal 'notes', tab
end

もし /^ルートページでノートタブを開きます。$/ do
  visit root_path(tab: 'notes')
  assert has_selector?('#notes-tab-panel')
  capture
end

もし /^メモに (.*?) と入力してメモを保存します。$/ do |body|
  @note_body = body
  within '#notes-tab-panel' do
    find('textarea[name="note[body]"]').set(body)
  end
  click_on 'メモを保存'
  assert_equal root_path, current_path
  tab = Rack::Utils.parse_query(URI.parse(current_url).query)['tab']
  assert_equal 'notes', tab
end

もし /^ノートタブに (.*?) が先頭表示されます。$/ do |body|
  assert_equal @note_body, body if @note_body
  within '#notes-tab-panel' do
    first_note_body = find('.note-item:first-child .note-body').text
    assert_equal body, first_note_body
  end
end

もし /^先頭メモを編集表示にします。$/ do
  within '#notes-tab-panel .note-item:first-child' do
    find('.note-item-display').double_click
    assert has_no_selector?('.note-item-edit-form[hidden]', wait: 3)
    assert has_button?('キャンセル')
  end
end

もし /^先頭メモの編集欄に (.*?) と入力します。$/ do |body|
  @editing_note_body = body
  within '#notes-tab-panel .note-item:first-child.note-item--editing' do
    find('textarea[name="note[body]"]').set(body)
  end
end

もし /^先頭メモの編集表示をキャンセルします。$/ do
  within '#notes-tab-panel .note-item:first-child.note-item--editing' do
    click_button 'キャンセル'
  end
  assert has_no_selector?('#notes-tab-panel .note-item:first-child.note-item--editing', wait: 3)
end

もし /^ノートタブの先頭メモ本文は (.*?) のままです。$/ do |body|
  assert_not_equal @editing_note_body, body
  within '#notes-tab-panel' do
    first_note_body = find('.note-item:first-child .note-body').text
    assert_equal body, first_note_body
  end
end
