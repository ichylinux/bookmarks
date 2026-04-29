もし /^モダンテーマでサインインします。$/ do
  user.preference.update!(theme: 'modern')
  sign_in user
end

もし /^ルートページを開くと、ドロワーは閉じています。$/ do
  visit root_path
  capture
  assert !page.has_css?('body.drawer-open'), 'ドロワーは最初から閉じているはずです'
end

もし /^ハンバーガーボタンをクリックすると、ドロワーが開きます。$/ do
  find('button.hamburger-btn', match: :first).click
  assert has_css?('body.drawer-open'), 'ドロワーが開いているはずです'
  capture
end

もし /^再度ハンバーガーボタンをクリックすると、ドロワーが閉じます。$/ do
  find('button.hamburger-btn', match: :first).click
  assert !page.has_css?('body.drawer-open'), 'ドロワーが閉じているはずです'
  capture
end

もし /^ルートページを開き、ドロワーを開いておきます。$/ do
  visit root_path
  find('button.hamburger-btn', match: :first).click
  assert has_css?('body.drawer-open'), 'ドロワーが開いているはずです'
  capture
end

もし /^オーバーレイをクリックすると、ドロワーが閉じます。$/ do
  page.execute_script('document.querySelector(".drawer-overlay").click()')
  assert !page.has_css?('body.drawer-open'), 'ドロワーが閉じているはずです'
  capture
end

もし /^Escapeキーを押すと、ドロワーが閉じます。$/ do
  find('body').send_keys(:escape)
  assert !page.has_css?('body.drawer-open'), 'ドロワーが閉じているはずです'
  capture
end

もし /^ドロワー内の「設定」リンクをクリックすると設定ページに遷移し、ドロワーが閉じています。$/ do
  within '.drawer' do
    click_link '設定'
  end
  assert_equal preferences_path, current_path
  assert !page.has_css?('body.drawer-open'), 'ページ遷移後にドロワーが閉じているはずです'
  capture
end

もし /^ルートページを開くと、ヘッダーにリンクなしでユーザー名が表示されます。$/ do
  visit root_path
  assert has_css?('#header .head-box .modern-user-email', text: user.display_name),
         'ヘッダーにユーザー名が表示されているはずです'
  assert !page.has_css?('#header .head-box .modern-user-email a'),
         'ユーザー名はリンクではないはずです'
  capture
end
