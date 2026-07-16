require 'uri'

def navigate_to_bookmark_gadget_column!
  return if has_selector?('#bookmark_gadget', visible: true, wait: 1)

  all('button.portal-column-tab').each do |tab|
    tab.click
    return if has_selector?('#bookmark_gadget', visible: true, wait: 1)
  end
end

def click_bookmark_gadget_new_link
  within '#bookmark_gadget' do
    header = find('.title--gadget-with-icon[data-gadget-icon="bookmark"]')
    unless header[:class].to_s.include?('title--gadget-actions-visible')
      find('.gadget-title-text').click
    end
  end
  el = find('#bookmark_gadget .bookmark-gadget-new-link', visible: :all)
  page.execute_script('arguments[0].click()', el)
end

もし /^ブックマーク管理画面を開き、ブックマーク追加用のアイコンをクリックします。$/ do
  sign_in user
  visit bookmarks_path
  assert has_selector?('.breadcrumbs')
  assert has_selector?('a.breadcrumbs-action-btn')
  find('a.breadcrumbs-action-btn[title="ブックマークを追加"]').click
  assert has_selector?('form')
  capture
end

もし /^URLを入力し、「URLから取得」ボタンでサイトのタイトルを取得します。$/ do
  @bookmark_url = URI.join(current_url, '/').to_s
  fill_in 'bookmark[url]', with: @bookmark_url
  click_button 'URLから取得'
  assert wait_until { find('#bookmark_title').value.present? }, 'URLからタイトルが取得されていません'
  @bookmark_title = find('#bookmark_title').value
  capture
end

もし /^ブックマークを追加ボタンをクリックしてブックマークを保存すると、トップページに表示されるようになります。$/ do
  click_on 'ブックマークを追加'
  visit '/'
  assert has_selector?('.root-bookmarks', text: @bookmark_title)
  capture
end

もし /^ブックマークガジェットが表示されたモバイル版ルートページを開きます。$/ do
  sign_in user
  ensure_mobile_viewport!
  visit root_path
  navigate_to_bookmark_gadget_column!
  assert has_selector?('#bookmark_gadget', visible: true)
  capture
end

もし /^ブックマークガジェットのヘッダをタップして操作を表示します。$/ do
  within '#bookmark_gadget' do
    find('.gadget-title-text').click
    assert has_selector?('.title--gadget-actions-visible')
  end
  capture
end

もし /^ブックマーク追加リンクをタップしてダイアログを開きます。$/ do
  click_bookmark_gadget_new_link
  assert has_selector?('dialog#bookmark-new-dialog[open]', visible: :all, wait: 5)
  capture
end

もし /^ダイアログの ブックマークを追加 ボタンをクリックしてブックマークを保存すると、ブックマークガジェットに表示されるようになります。$/ do
  within '.bookmark-new-dialog__form' do
    click_on 'ブックマークを追加'
  end
  assert wait_until { has_selector?('#bookmark_gadget .root-bookmarks', text: @bookmark_title) },
         'ブックマークガジェットに新しいブックマークが表示されていません'
  capture
end
