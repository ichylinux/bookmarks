require 'test_helper'

class WelcomeController::RootPathTest < ActionDispatch::IntegrationTest
  def test_未ログインでrootはランディングページを表示する
    get root_path
    assert_response :success
    assert_select '.landing-page', count: 1
  end

  def test_rootにサインアップとログインCTAが表示される
    get root_path
    assert_response :success
    assert_select 'a.landing-cta--primary[href=?]', new_user_registration_path
    assert_select 'a.landing-cta--secondary[href=?]', new_user_session_path
  end

  def test_rootにプライバシーと利用規約へのリンクが表示される
    get root_path
    assert_response :success
    assert_select '.landing-footer-nav a[href=?]', privacy_path
    assert_select '.landing-footer-nav a[href=?]', terms_path
  end

  def test_rootは英語ロケールで英語見出しを表示する
    get root_path, headers: { 'Accept-Language' => 'en-US,en;q=0.9,ja;q=0.8' }
    assert_response :success
    assert_select 'html[lang=?]', 'en'
    assert_includes response.body, 'Simplify your daily information flow'
  end

  def test_rootに4つのサインイン連携カードが表示される
    get root_path
    assert_response :success
    assert_select 'section.landing-integrations .landing-integration-card', count: 4
    assert_includes response.body, I18n.t('landing.integrations.google.title', locale: :ja)
    assert_includes response.body, I18n.t('landing.integrations.facebook.title', locale: :ja)
  end

  def test_rootのヒーローにブランド表示がある
    get root_path
    assert_response :success
    assert_select '.landing-brand-lockup img.landing-brand-icon[alt=?]', 'Bookmarks'
    assert_includes response.body, I18n.t('landing.header.subtitle', locale: :ja)
  end

  def test_未ログインでrootへ英語優先でアクセスすると英語ランディングが表示される
    get root_path, headers: { 'Accept-Language' => 'en-US,en;q=0.9,ja;q=0.8' }
    assert_response :success
    assert_select '.landing-page', count: 1
  end

  def test_changelogセクションがゲストに表示される
    get root_path
    assert_response :success
    assert_select 'section.landing-changelog', count: 1
  end

  def test_changelogカードに4要素が表示される
    get root_path
    assert_response :success
    assert_select '.changelog-date'
    assert_select '.changelog-tag'
    assert_select '.changelog-headline'
    assert_select '.changelog-description'
  end

  def test_日本語ロケールでchangelog見出しが新着情報になる
    get root_path
    assert_response :success
    assert_includes response.body, '新着情報'
  end

  def test_英語ロケールでchangelog見出しがWhatsNewになる
    get root_path, headers: { 'Accept-Language' => 'en-US,en;q=0.9,ja;q=0.8' }
    assert_response :success
    assert_select '.changelog-heading', text: /What.s New/
  end

  def test_ログイン済みユーザーのrootはダッシュボードを表示する
    sign_in User.first
    get root_path
    assert_response :success
    assert_select '.landing-page', count: 0
  end

  def test_ログイン済みユーザーのrootにはランディングCTAが表示されない
    sign_in User.first
    get root_path
    assert_response :success
    assert_select 'a.landing-cta--primary[href=?]', new_user_registration_path, count: 0
  end
end
