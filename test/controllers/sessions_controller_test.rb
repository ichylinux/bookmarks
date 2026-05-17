require 'test_helper'

class SessionsControllerTest < ActionDispatch::IntegrationTest

  # AUTHI18N-01: Sign-in page renders in Japanese (default locale)
  def test_サインインページが日本語でレンダリングされる
    get new_user_session_path
    assert_response :success
    assert_select 'html[lang=?]', 'ja'
    assert_select '.auth-intro', text: I18n.t('landing.auth.sign_in_intro', locale: :ja)
    assert_select 'input[type=submit][value=?]',
      I18n.t('devise.sessions.new.sign_in', locale: :ja)
  end

  # AUTHI18N-01: Sign-in page renders in English via Accept-Language
  def test_サインインページが英語でレンダリングされる
    get new_user_session_path, headers: { 'Accept-Language' => 'en' }
    assert_response :success
    assert_select 'html[lang=?]', 'en'
    assert_select '.auth-intro', text: I18n.t('landing.auth.sign_in_intro', locale: :en)
    assert_select 'input[type=submit][value=?]',
      I18n.t('devise.sessions.new.sign_in', locale: :en)
  end

  # AUTHI18N-01 + AUTHI18N-03: Failed sign-in flash appears in Japanese
  def test_サインイン失敗時のflashが日本語で表示される
    post user_session_path,
      params: { user: { email: user.email, password: 'wrongpass' } }
    assert_redirected_to new_user_session_path
    follow_redirect!
    expected = I18n.t('devise.sessions.invalid',
      authentication_keys: User.human_attribute_name(:email, locale: :ja),
      locale: :ja)
    assert_select '.flash-alert', text: expected
    assert_select '.flash-alert button.flash-dismiss[data-dismiss-flash][aria-label=?]',
      I18n.t('flash.dismiss', locale: :ja), count: 1
  end

  # AUTHI18N-03: Failed sign-in flash appears in English
  def test_サインイン失敗時のflashが英語で表示される
    post user_session_path,
      params: { user: { email: user.email, password: 'wrongpass' } },
      headers: { 'Accept-Language' => 'en' }
    assert_redirected_to new_user_session_path
    get new_user_session_path, headers: { 'Accept-Language' => 'en' }
    expected = I18n.t('devise.sessions.invalid',
      authentication_keys: User.human_attribute_name(:email, locale: :en),
      locale: :en)
    assert_select '.flash-alert', text: expected
    assert_select '.flash-alert button.flash-dismiss[data-dismiss-flash][aria-label=?]',
      I18n.t('flash.dismiss', locale: :en), count: 1
  end

  def test_サインアウト時のflashが日本語で表示される
    sign_in user
    delete destroy_user_session_path
    assert_response :redirect
    assert_equal I18n.t('devise.sessions.signed_out', locale: :ja), flash[:notice]
  end

  def test_サインアウト時のflashが英語で表示される
    user.preference.update!(locale: 'en')
    sign_in user
    delete destroy_user_session_path, headers: { 'Accept-Language' => 'en-US,en;q=0.9,ja;q=0.8' }
    assert_response :redirect
    assert_equal I18n.t('devise.sessions.signed_out', locale: :en), flash[:notice]
  end

end
