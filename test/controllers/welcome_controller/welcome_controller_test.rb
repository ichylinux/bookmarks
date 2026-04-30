require 'test_helper'

class WelcomeController::WelcomeControllerTest < ActionDispatch::IntegrationTest

  def test_トップページ
    sign_in user
    get root_path
    assert_response :success
    assert_equal '/', path
  end

  def test_ブックマークを新しいタブで開く設定がオンのときリンクにtarget_blankが付く
    sign_in user
    user.preference.update!(open_links_in_new_tab: true)
    get root_path
    assert_response :success
    assert_select '#bookmark_gadget a[href=?][target=?][rel=?]', 'www.example.com', '_blank', 'noopener noreferrer', text: 'ブックマーク1'
  end

  def test_ブックマークを新しいタブで開く設定がオフのときリンクにtarget_blankが付かない
    sign_in user
    user.preference.update!(open_links_in_new_tab: false)
    get root_path
    assert_response :success
    assert_select '#bookmark_gadget a[href=?]', 'www.example.com', text: 'ブックマーク1'
    assert_select '#bookmark_gadget a[href=?][target=?]', 'www.example.com', '_blank', count: 0
  end

  def test_シンプルテーマでウェルカムにホームとノートのタブボタンが表示される
    user.preference.update!(theme: 'simple')
    sign_in user
    get root_path
    assert_response :success
    assert_select 'nav.simple-tabstrip', count: 1
    assert_select 'button.simple-tab[data-simple-tab=?]', 'home', text: /ホーム/, count: 1
    assert_select 'button.simple-tab[data-simple-tab=?]', 'notes', text: /ノート/, count: 1
    assert_select '#simple-home-panel', count: 1
    assert_select '#notes-tab-panel', count: 1
  end

  def test_シンプルテーマでtab_notesクエリのときノートパネルが非表示クラスでホームが隠される
    user.preference.update!(theme: 'simple')
    sign_in user
    get root_path(tab: 'notes')
    assert_response :success
    assert_select '#simple-home-panel.simple-tab-panel--hidden', count: 1
    assert_select '#notes-tab-panel.simple-tab-panel--hidden', count: 0
  end

  def test_シンプルテーマで不正なtabクエリはホームを表示する
    user.preference.update!(theme: 'simple')
    sign_in user
    get root_path(tab: 'evil')
    assert_response :success
    assert_select '#simple-home-panel.simple-tab-panel--hidden', count: 0
    assert_select '#notes-tab-panel.simple-tab-panel--hidden', count: 1
  end

end
