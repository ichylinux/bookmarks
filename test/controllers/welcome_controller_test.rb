require 'test_helper'

class WelcomeControllerTest < ActionDispatch::IntegrationTest

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

end
