require 'uri'

もし /^ブックマーク管理画面を開き、ブックマーク追加用のアイコンをクリックします。$/ do
  sign_in user
  visit bookmarks_path
  assert has_selector?('.breadcrumbs')
  assert has_selector?('a.breadcrumbs-create-bookmark')
  find('a.breadcrumbs-create-bookmark').click
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
