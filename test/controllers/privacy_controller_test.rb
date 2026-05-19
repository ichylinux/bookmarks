require 'test_helper'

class PrivacyControllerTest < ActionDispatch::IntegrationTest
  def test_未認証でprivacyは200を返す
    get privacy_path
    assert_response :success
  end

  def test_privacyはランディングページ構造を使う
    get privacy_path
    assert_response :success
    assert_select 'main.landing-page', count: 1
  end

  def test_privacyは日本語ロケールで日本語タイトルを表示する
    get privacy_path
    assert_response :success
    assert_select 'h1', text: 'プライバシーポリシー'
  end

  def test_privacyは英語ロケールで英語タイトルを表示する
    get privacy_path, params: { locale: 'en' }
    assert_response :success
    assert_select 'h1', text: 'Privacy Policy'
  end

  def test_privacyは認証リダイレクトしない
    get privacy_path
    assert_response :success
    refute_equal new_user_session_path, response.location
  end

  def test_privacyはセクション見出しを含む
    get privacy_path
    assert_response :success
    assert_select 'h2.policy-section-heading'
  end
end
