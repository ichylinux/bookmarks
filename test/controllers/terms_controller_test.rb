require 'test_helper'

class TermsControllerTest < ActionDispatch::IntegrationTest
  def test_未認証でtermsは200を返す
    get terms_path
    assert_response :success
  end

  def test_termsはランディングページ構造を使う
    get terms_path
    assert_response :success
    assert_select 'main.landing-page', count: 1
  end

  def test_termsは日本語ロケールで日本語タイトルを表示する
    get terms_path
    assert_response :success
    assert_select 'h1', text: '利用規約'
  end

  def test_termsは英語ロケールで英語タイトルを表示する
    get terms_path, params: { locale: 'en' }
    assert_response :success
    assert_select 'h1', text: 'Terms of Service'
  end

  def test_termsは認証リダイレクトしない
    get terms_path
    assert_response :success
    refute_equal new_user_session_path, response.location
  end

  def test_termsはセクション見出しを含む
    get terms_path
    assert_response :success
    assert_select 'h2.policy-section-heading'
  end
end
