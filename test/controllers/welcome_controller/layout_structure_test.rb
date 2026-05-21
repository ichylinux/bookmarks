require 'test_helper'

class WelcomeController::LayoutStructureTest < ActionDispatch::IntegrationTest

  def test_モダンテーマでハンバーガーボタンが表示される
    user.preference.update!(theme: 'modern')
    sign_in user
    get root_path
    assert_response :success
    assert_select 'button.hamburger-btn[aria-label=?]', 'メニュー', count: 1
  end

  def test_デフォルトテーマでもハンバーガーボタンが存在する
    sign_in user
    get root_path
    assert_response :success
    assert_select 'button.hamburger-btn', count: 1
  end

  def test_ヘッダーのアプリアイコンがルートへのリンクになる
    sign_in user
    get root_path
    assert_response :success
    assert_select '#header a[href=?] img.header-icon[src=?][alt=?]', root_path, '/icon.svg', 'Bookmarks', count: 1
  end

  def test_モダンテーマでドロワーが存在する
    user.preference.update!(theme: 'modern')
    sign_in user
    get root_path
    assert_response :success
    assert_select 'div.drawer', count: 1
    assert_select 'div.drawer-overlay', count: 1
  end

  def test_ドロワーに全ナビリンクが含まれる
    user.preference.update!(theme: 'modern')
    sign_in user
    get root_path
    assert_response :success
    assert_select '.drawer a[href=?]', root_path
    assert_select '.drawer a[href=?]', preferences_path
    assert_select '.drawer a[href=?]', bookmarks_path
    assert_select '.drawer a[href=?]', todos_path
    assert_select '.drawer a[href=?]', feeds_path
    assert_select '.drawer a[href=?]', mastodon_accounts_path
    assert_select '.drawer a[href=?]', privacy_path
    assert_select '.drawer a[href=?]', terms_path
    assert_select '.drawer a[href=?]', destroy_user_session_path
    assert_select '.drawer a[href=?][data-method=?]', destroy_user_session_path, 'delete'
  end

  def test_ドロワーはwrapperの外にあり_bodyの直下にある
    user.preference.update!(theme: 'modern')
    sign_in user
    get root_path
    assert_response :success
    assert_select 'body > div.drawer', count: 1
    assert_select '.wrapper div.drawer', count: 0
  end

  def test_ドロワー内のnav要素が9リンクを含む
    non_admin = User.find(2)
    non_admin.preference.update!(theme: 'modern')
    sign_in non_admin
    get root_path
    assert_response :success
    assert_select '.drawer > nav', count: 1
    assert_select '.drawer nav a', count: 9
    assert_select '.drawer .drawer-nav-icon', count: 9
    assert_select '.drawer-nav-divider[role=?]', 'separator', count: 1
    assert_select '.drawer-nav-section--primary a', count: 6
    assert_select '.drawer-nav-section--secondary a', count: 3
    assert_select '.drawer a[href=?]', admin_x_api_usages_path, count: 0
  end

  def test_管理者のドロワーにX_API利用状況リンクが含まれる
    admin = User.find(1)
    admin.preference.update!(theme: 'modern')
    sign_in admin
    get root_path
    assert_response :success
    assert_select '.drawer a[href=?]', admin_x_api_usages_path, count: 1
    assert_select '.drawer nav a', count: 10
    assert_select '.drawer-nav-section--primary a', count: 6
    assert_select '.drawer-nav-section--admin a', count: 1
    assert_select '.drawer-nav-divider[role=?]', 'separator', count: 2
  end

  def test_クラシックテーマでハンバーガーとドロワーが表示される
    user.preference.update!(theme: 'classic')
    sign_in user
    get root_path
    assert_response :success
    assert_select 'button.hamburger-btn', count: 1
    assert_select 'div.drawer', count: 1
    assert_select 'div.drawer-overlay', count: 1
  end

  def test_シンプルテーマではドロワーとハンバーガーがなくシンプルメニューが表示される
    user.preference.update!(theme: 'simple')
    sign_in user
    get root_path
    assert_response :success
    assert_select 'button.hamburger-btn', count: 0
    assert_select 'div.drawer', count: 0
    assert_select 'div.drawer-overlay', count: 0
    assert_select 'body.simple', count: 1
    assert_select 'ul.navigation', count: 1
    assert_select 'ul.navigation a[href=?]', root_path
    assert_select '.menu-divider[role=?]', 'separator', count: 2
    assert_select '.menu-section--primary a', count: 5
    assert_select '.menu-section--admin a', count: 1
    assert_select '.menu-section--secondary a', count: 3
    assert_select '.menu a[href=?]', admin_x_api_usages_path, count: 1
    assert_select '.menu a[href=?]', privacy_path
    assert_select '.menu a[href=?]', terms_path
  end

  def test_シンプルテーマの非管理者メニューにX_API利用状況リンクがない
    non_admin = User.find(2)
    non_admin.preference.update!(theme: 'simple')
    sign_in non_admin
    get root_path
    assert_response :success
    assert_select '.menu a[href=?]', admin_x_api_usages_path, count: 0
    assert_select '.menu-section--primary a', count: 5
  end

  def test_非ログイン時はランディングページが表示される
    get root_path
    assert_response :success
    assert_select '.landing-page', count: 1
  end

  def test_モダンテーマではuse_noteオフのときノートパネルが出力されない
    user.preference.update!(theme: 'modern', use_note: false)
    sign_in user
    get root_path
    assert_response :success
    assert_select '#notes-tab-panel', count: 0
  end

  def test_クラシックテーマではuse_noteオフのときノートパネルが出力されない
    user.preference.update!(theme: 'classic', use_note: false)
    sign_in user
    get root_path
    assert_response :success
    assert_select '#notes-tab-panel', count: 0
  end

  def test_モダンテーマでuse_noteオンのときドロワーにノートリンクはない
    user.preference.update!(theme: 'modern', use_note: true, locale: 'ja')
    sign_in user
    get root_path
    assert_response :success
    assert_select 'html[lang=?]', 'ja'
    assert_select '.drawer a[href=?]', root_path(tab: 'notes'), count: 0
  end

  def test_モダンテーマでuse_noteオンのときヘッダーにノートアイコンリンクがある
    user.preference.update!(theme: 'modern', use_note: true, locale: 'ja')
    sign_in user
    get root_path
    assert_response :success
    assert_select '#header .head-box.head-box--with-note-action', count: 1
    assert_select '#header a.head-note-btn[href=?][aria-label=?]', root_path(tab: 'notes'), 'ノート', count: 1
    assert_select '#header a.head-note-btn.head-note-btn--active', count: 0
    assert_select '#header a.head-note-btn svg', count: 1
  end

  def test_モダンテーマでノート表示中はヘッダーアイコンがホームへ向きアクティブ表示になる
    user.preference.update!(theme: 'modern', use_note: true, locale: 'ja')
    sign_in user
    get root_path(tab: 'notes')
    assert_response :success
    assert_select '#header a.head-note-btn.head-note-btn--active[href=?][aria-label=?]', root_path, 'ブックマーク画面に戻る', count: 1
  end

  def test_モダンテーマでuse_noteオフのときヘッダーにノートアイコンがない
    user.preference.update!(theme: 'modern', use_note: false)
    sign_in user
    get root_path
    assert_response :success
    assert_select '#header .head-box.head-box--with-note-action', count: 0
    assert_select '#header a.head-note-btn', count: 0
  end

  def test_クラシックテーマでuse_noteオンのときヘッダーにノートアイコンリンクがある
    user.preference.update!(theme: 'classic', use_note: true, locale: 'en')
    sign_in user
    get root_path
    assert_response :success
    assert_select '#header a.head-note-btn[href=?][aria-label=?]', root_path(tab: 'notes'), 'Note', count: 1
    assert_select '#header a.head-note-btn.head-note-btn--active', count: 0
  end

  def test_クラシックテーマでノート表示中はヘッダーアイコンがホームへ向く
    user.preference.update!(theme: 'classic', use_note: true, locale: 'en')
    sign_in user
    get root_path(tab: 'notes')
    assert_response :success
    assert_select '#header a.head-note-btn.head-note-btn--active[href=?][aria-label=?]', root_path, 'Return to bookmarks', count: 1
  end

  def test_シンプルテーマではヘッダーにノートアイコンがない
    user.preference.update!(theme: 'simple', use_note: true)
    sign_in user
    get root_path
    assert_response :success
    assert_select '#header a.head-note-btn', count: 0
  end

  def test_モダンテーマでuse_noteオンのときドロワーnavは9リンク
    non_admin = User.find(2)
    non_admin.preference.update!(theme: 'modern', use_note: true)
    sign_in non_admin
    get root_path
    assert_response :success
    assert_select '.drawer nav a', count: 9
  end

  def test_モダンテーマでポータル列タブと既定の列状態が出力される
    user.preference.update!(theme: 'modern')
    sign_in user
    get root_path
    assert_response :success
    assert_select '.portal-column-tabs button.portal-column-tab', count: 3
    assert_select '.portal.portal--column-active-0', count: 1
    assert_select 'button.portal-column-tab--active', count: 1
  end

  def test_列ナビ非表示設定ではタブが出力されずポータル列は残る
    user.preference.update!(theme: 'modern', show_column_nav_buttons: false)
    sign_in user
    get root_path
    assert_response :success
    assert_select '.portal-column-tabs', count: 0
    assert_select '.portal .portal-column', count: 3
    assert_select '.portal.portal--column-active-0', count: 1
  end

  def test_クラシックテーマでポータル列タブと既定の列状態が出力される
    user.preference.update!(theme: 'classic')
    sign_in user
    get root_path
    assert_response :success
    assert_select '.portal-column-tabs button.portal-column-tab', count: 3
    assert_select '.portal.portal--column-active-0', count: 1
  end

  def test_シンプルテーマでポータル列タブと既定の列状態が出力される
    user.preference.update!(theme: 'simple')
    sign_in user
    get root_path
    assert_response :success
    assert_select '.portal-column-tabs button.portal-column-tab', count: 3
    assert_select '.portal.portal--column-active-0', count: 1
  end

  def test_portal_column_count_4のとき4列のportal_columnが出力される
    user.preference.update!(portal_column_count: 4)
    sign_in user
    get root_path
    assert_response :success
    assert_select '.portal .portal-column', count: 4
    assert_select '.portal.portal--4col', count: 1
  end

  def test_portal_column_count_3のとき3列のportal_columnが出力される
    user.preference.update!(portal_column_count: 3)
    sign_in user
    get root_path
    assert_response :success
    assert_select '.portal .portal-column', count: 3
    assert_select '.portal.portal--4col', count: 0
  end

  def test_カスタム列幅比率がportal_columnのstyleに出力される
    user.preference.update!(portal_column_count: 4)
    user.preference.update!(portal_column_widths: [40, 20, 20, 20])
    assert_equal [40, 20, 20, 20], user.preference.reload.portal_column_widths
    sign_in user
    get root_path
    assert_response :success
    assert_select '.portal.portal--custom-widths', count: 1
    assert_select '.portal-column[style*="--portal-col-width-pct"]', count: 4
    assert_match(/--portal-col-width-pct: 40%/, response.body)
    assert_match(/--portal-col-width-pct: 20%/, response.body)
  end

end
