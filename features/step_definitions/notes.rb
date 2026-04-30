# frozen_string_literal: true

require 'uri'

もし /^シンプルテーマでサインインします。$/ do
  user.preference.update!(theme: 'simple')
  Note.where(user_id: user.id).delete_all
  sign_in user
end

もし /^ルートページでノートタブを開きます。$/ do
  visit root_path
  find('button.simple-tab[data-simple-tab="notes"]').click
  assert has_selector?('#notes-tab-panel')
  assert has_selector?('button.simple-tab.simple-tab--active[data-simple-tab="notes"]')
  capture
end

もし /^メモに (.*?) と入力して保存します。$/ do |body|
  @note_body = body
  within '#notes-tab-panel' do
    find('textarea[name="note[body]"]').set(body)
  end
  click_on '保存'
  assert_equal root_path, current_path
  tab = Rack::Utils.parse_query(URI.parse(current_url).query)['tab']
  assert_equal 'notes', tab
end

もし /^ノートタブに (.*?) が先頭表示されます。$/ do |body|
  assert_equal @note_body, body if @note_body
  assert has_selector?('button.simple-tab.simple-tab--active[data-simple-tab="notes"]')
  within '#notes-tab-panel' do
    assert has_selector?('.note-item:first-child .note-body', text: body)
  end
end
