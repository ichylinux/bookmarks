require 'test_helper'

class LandingControllerTest < ActionDispatch::IntegrationTest
  def test_未ログインでもlandingを表示できる
    get landing_path
    assert_response :success
    assert_select '.landing-page', count: 1
  end

  def test_landingにサインアップとログインCTAが表示される
    get landing_path
    assert_response :success
    assert_select 'a.landing-cta--primary[href=?]', new_user_registration_path
    assert_select 'a.landing-cta--secondary[href=?]', new_user_session_path
  end

  def test_landingは英語ロケールで英語見出しを表示する
    get landing_path, headers: { 'Accept-Language' => 'en-US,en;q=0.9,ja;q=0.8' }
    assert_response :success
    assert_select 'html[lang=?]', 'en'
    assert_includes response.body, 'Simplify your daily information flow'
  end

  def test_未ログインでrootは従来通りサインイン画面へリダイレクトされる
    get root_path
    assert_response :redirect
    assert_redirected_to new_user_session_path
  end
end
