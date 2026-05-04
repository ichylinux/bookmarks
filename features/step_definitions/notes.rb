# frozen_string_literal: true

require 'uri'

もし /^シンプルテーマでサインインします。$/ do
  user.preference.update!(theme: 'simple', use_note: true)
  Note.where(user_id: user.id).delete_all
  sign_in user
end

もし /^モダンテーマでノートを有効にしてサインインします。$/ do
  user.preference.update!(theme: 'modern', use_note: true, locale: 'ja')
  Note.where(user_id: user.id).delete_all
  sign_in user
end

もし /^ドロワーからノート画面を開きます。$/ do
  visit root_path
  find('button.hamburger-btn', match: :first).click
  within '.drawer' do
    click_link 'ノート'
  end
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
    assert has_selector?('.note-item:first-child .note-body', text: body)
  end
end
