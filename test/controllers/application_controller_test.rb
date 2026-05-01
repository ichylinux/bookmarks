require 'test_helper'

class ApplicationControllerTest < ActionDispatch::IntegrationTest

  # VERI18N-01: 保存済みlocaleの経路
  def test_保存済みlocaleがenのユーザは英語でレンダリングされる
    user.preference.update!(locale: 'en')
    sign_in user
    get root_path
    assert_response :success
    assert_select 'html[lang=?]', 'en'
  end

  # VERI18N-01: Accept-Language経路
  def test_AcceptLanguageがenのリクエストは英語でレンダリングされる
    user.preference.update!(locale: nil)
    sign_in user
    get root_path, headers: { 'Accept-Language' => 'en-US,en;q=0.9,ja;q=0.8' }
    assert_response :success
    assert_select 'html[lang=?]', 'en'
  end

  # VERI18N-01: 無効locale (I18N-03)
  def test_無効なlocaleは無視されてデフォルトの日本語になる
    user.preference.update!(locale: nil)
    sign_in user
    get root_path, headers: { 'Accept-Language' => 'fr-FR,fr;q=0.9' }
    assert_response :success
    assert_select 'html[lang=?]', 'ja'
  end

  # VERI18N-01: デフォルト :ja
  def test_locale未設定かつAcceptLanguage未指定の場合はデフォルト日本語
    user.preference.update!(locale: nil)
    sign_in user
    get root_path
    assert_response :success
    assert_select 'html[lang=?]', 'ja'
  end

  def test_chromeはja_localeでホームと設定とメニューariaを含む
    user.preference.update!(locale: 'ja')
    sign_in user
    get root_path
    assert_response :success
    assert_select 'a', text: 'Home'
    assert_select 'a', text: '設定'
    assert_select 'button.hamburger-btn[aria-label=?]', 'メニュー'
  end

  def test_chromeはen_localeでHomeとPreferencesとMenuariaを含む
    user.preference.update!(locale: 'en')
    sign_in user
    get root_path
    assert_response :success
    assert_select 'a', text: 'Home'
    assert_select 'a', text: 'Preferences'
    assert_select 'button.hamburger-btn[aria-label=?]', 'Menu'
  end

end
