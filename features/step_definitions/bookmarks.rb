もし /^ブックマーク管理画面を開き、ブックマーク追加用のアイコンをクリックします。$/ do
  sign_in user
  visit bookmarks_path
  capture
  find('a.breadcrumbs-create-bookmark').click
  assert has_selector?('form')
  capture
end

もし /^URLを入力すると、自動的にサイトのタイトルが保管されます。$/ do
  @bookmark_url = 'http://example.com'
  fill_in 'bookmark[url]', with: @bookmark_url
  find('#bookmark_url').send_keys(:tab)
  assert wait_until { find('#bookmark_title').value.present? }, 'URLからタイトルが自動取得されていません'
  @bookmark_title = find('#bookmark_title').value
  capture
end

もし /^登録ボタンをクリックしてブックマークを保存すると、トップページに表示されるようになります。$/ do
  click_on '登録する'
  visit '/'
  assert has_selector?('.root-bookmarks', text: @bookmark_title)
  capture
end
