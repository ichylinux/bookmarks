もし /^モダンテーマでサインインします。$/ do
  user.preference.update!(theme: 'modern')
  sign_in user
end

もし /^クラシックテーマでサインインします。$/ do
  user.preference.update!(theme: 'classic')
  sign_in user unless current_user&.id == user.id
end

もし /^検証用シンプルテーマでサインインします。$/ do
  user.preference.update!(theme: 'simple')
  sign_in user unless current_user&.id == user.id
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
  assert has_css?('#header .head-box .head-user-email', text: user.display_name),
         'ヘッダーにユーザー名が表示されているはずです'
  assert !page.has_css?('#header .head-box .head-user-email a'),
         'ユーザー名はリンクではないはずです'
  capture
end

もし /^ルートページを開くと、シンプルメニューが表示され、ドロワー関連要素はありません。$/ do
  visit root_path
  assert has_css?('body.simple'), 'シンプルテーマであるはずです'
  assert has_css?('ul.navigation'), 'シンプルメニューが表示されているはずです'
  assert !page.has_css?('button.hamburger-btn'), 'ハンバーガーボタンは表示されないはずです'
  assert !page.has_css?('div.drawer'), 'ドロワーは表示されないはずです'
  assert !page.has_css?('div.drawer-overlay'), 'オーバーレイは表示されないはずです'
  assert !page.has_css?('body.drawer-open'), 'ドロワー状態は付与されないはずです'
  capture
end

もし /^Escapeキーを押してもドロワーは開きません。$/ do
  find('body').send_keys(:escape)
  assert !page.has_css?('body.drawer-open'), 'Escape押下後もドロワーは開かないはずです'
  capture
end

もし /^シンプルメニューの「設定」リンクをクリックすると設定ページに遷移します。$/ do
  within 'ul.navigation' do
    find('li.email > a', match: :first).click
    assert has_css?('li.email .menu:not(.hidden)'), 'シンプルメニューのドロップダウンが開いているはずです'
    find("li.email .menu a[href='#{preferences_path}']").click
  end
  assert_equal preferences_path, current_path
  assert !page.has_css?('body.drawer-open'), '遷移後もドロワー状態は付与されないはずです'
  capture
end

もし /^ルートページを開きます。$/ do
  visit root_path
  capture
end

もし /^ページを再読み込みします。$/ do
  visit current_path
  capture
end

もし /^localStorageの列状態を不正値に設定します。$/ do
  visit root_path
  page.execute_script("window.localStorage.setItem('portalMobileActiveColumn', '999')")
  capture
end

もし /^ポータル列タブが3つ表示されています。$/ do
  assert has_css?('.portal-column-tabs'), 'ポータル列タブ枠があるはずです'
  assert has_css?('button.portal-column-tab', count: 3), '列タブが3つあるはずです'
  capture
end

もし /^2列目のポータル列タブをクリックします。$/ do
  find('button.portal-column-tab[data-portal-column-index="1"]').click
  capture
end

もし /^3列目のポータル列タブをクリックします。$/ do
  find('button.portal-column-tab[data-portal-column-index="2"]').click
  capture
end

もし /^2列目のポータル列がアクティブです。$/ do
  assert has_css?('.portal.portal--column-active-1'), '2列目のポータルがアクティブなはずです'
  assert has_css?(
    'button.portal-column-tab--active[data-portal-column-index="1"]',
    count: 1
  ), '2列目のタブがアクティブなはずです'
  capture
end

もし /^3列目のポータル列がアクティブです。$/ do
  assert has_css?('.portal.portal--column-active-2'), '3列目のポータルがアクティブなはずです'
  assert has_css?(
    'button.portal-column-tab--active[data-portal-column-index="2"]',
    count: 1
  ), '3列目のタブがアクティブなはずです'
  capture
end

もし /^1列目のポータルを左にスワイプします。$/ do
  page.execute_script(<<~JS)
    (function() {
      const portal = document.querySelector('.portal');
      function makeTouch(x, y) {
        return new Touch({ identifier: 1, target: portal, clientX: x, clientY: y, radiusX: 10, radiusY: 10, rotationAngle: 0, force: 1 });
      }
      function fire(type, x, y) {
        const t = makeTouch(x, y);
        portal.dispatchEvent(new TouchEvent(type, { touches: type === 'touchend' ? [] : [t], changedTouches: [t], bubbles: true, cancelable: true }));
      }
      fire('touchstart', 290, 400);
      fire('touchmove', 195, 400);
      fire('touchmove', 100, 400);
      fire('touchend', 100, 400);
    })();
  JS
  capture
end

もし /^1列目のポータルを右にスワイプします。$/ do
  page.execute_script(<<~JS)
    (function() {
      const portal = document.querySelector('.portal');
      function makeTouch(x, y) {
        return new Touch({ identifier: 1, target: portal, clientX: x, clientY: y, radiusX: 10, radiusY: 10, rotationAngle: 0, force: 1 });
      }
      function fire(type, x, y) {
        const t = makeTouch(x, y);
        portal.dispatchEvent(new TouchEvent(type, { touches: type === 'touchend' ? [] : [t], changedTouches: [t], bubbles: true, cancelable: true }));
      }
      fire('touchstart', 100, 400);
      fire('touchmove', 195, 400);
      fire('touchmove', 290, 400);
      fire('touchend', 290, 400);
    })();
  JS
  capture
end

もし /^アクティブなポータルを右にスワイプします。$/ do
  page.execute_script(<<~JS)
    (function() {
      const portal = document.querySelector('.portal');
      function makeTouch(x, y) {
        return new Touch({ identifier: 1, target: portal, clientX: x, clientY: y, radiusX: 10, radiusY: 10, rotationAngle: 0, force: 1 });
      }
      function fire(type, x, y) {
        const t = makeTouch(x, y);
        portal.dispatchEvent(new TouchEvent(type, { touches: type === 'touchend' ? [] : [t], changedTouches: [t], bubbles: true, cancelable: true }));
      }
      fire('touchstart', 100, 400);
      fire('touchmove', 195, 400);
      fire('touchmove', 290, 400);
      fire('touchend', 290, 400);
    })();
  JS
  capture
end

もし /^1列目のポータルを縦方向にスワイプします。$/ do
  page.execute_script(<<~JS)
    (function() {
      const portal = document.querySelector('.portal');
      function makeTouch(x, y) {
        return new Touch({ identifier: 1, target: portal, clientX: x, clientY: y, radiusX: 10, radiusY: 10, rotationAngle: 0, force: 1 });
      }
      function fire(type, x, y) {
        const t = makeTouch(x, y);
        portal.dispatchEvent(new TouchEvent(type, { touches: type === 'touchend' ? [] : [t], changedTouches: [t], bubbles: true, cancelable: true }));
      }
      fire('touchstart', 195, 200);
      fire('touchmove', 196, 350);
      fire('touchmove', 196, 500);
      fire('touchend', 196, 500);
    })();
  JS
  capture
end

もし /^1列目のポータル列がアクティブのままです。$/ do
  assert has_css?('.portal.portal--column-active-0'), '1列目のポータルがアクティブのままであるはずです'
  assert has_css?(
    'button.portal-column-tab--active[data-portal-column-index="0"]',
    count: 1
  ), '1列目のタブがアクティブのままであるはずです'
  capture
end
