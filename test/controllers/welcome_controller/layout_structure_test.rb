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

  def test_ドロワー内のnav要素が6リンクを含む
    user.preference.update!(theme: 'modern')
    sign_in user
    get root_path
    assert_response :success
    assert_select '.drawer > nav', count: 1
    assert_select '.drawer > nav > a', count: 6
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
  end

  def test_非ログイン時はドロワーが存在しない
    get root_path
    assert_response :redirect
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
    assert_select '#header a.head-note-btn[href=?][aria-label=?]', root_path(tab: 'notes'), 'ノート', count: 1
    assert_select '#header a.head-note-btn svg', count: 1
  end

  def test_モダンテーマでuse_noteオフのときヘッダーにノートアイコンがない
    user.preference.update!(theme: 'modern', use_note: false)
    sign_in user
    get root_path
    assert_response :success
    assert_select '#header a.head-note-btn', count: 0
  end

  def test_クラシックテーマでuse_noteオンのときヘッダーにノートアイコンリンクがある
    user.preference.update!(theme: 'classic', use_note: true, locale: 'en')
    sign_in user
    get root_path
    assert_response :success
    assert_select '#header a.head-note-btn[href=?][aria-label=?]', root_path(tab: 'notes'), 'Note', count: 1
  end

  def test_シンプルテーマではヘッダーにノートアイコンがない
    user.preference.update!(theme: 'simple', use_note: true)
    sign_in user
    get root_path
    assert_response :success
    assert_select '#header a.head-note-btn', count: 0
  end

  def test_モダンテーマでuse_noteオンのときドロワーnavは6リンク
    user.preference.update!(theme: 'modern', use_note: true)
    sign_in user
    get root_path
    assert_response :success
    assert_select '.drawer > nav > a', count: 6
  end

end
