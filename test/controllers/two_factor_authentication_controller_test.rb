require 'test_helper'

class TwoFactorAuthenticationControllerTest < ActionDispatch::IntegrationTest
  def test_sign_in_without_2fa
    post user_session_path, params: { user: { email: user.email, password: 'testtest' } }
    assert_response :redirect
    follow_redirect!
    assert_equal '/', path
  end

  def test_sign_in_with_2fa_redirects_to_otp
    user.enable_two_factor!
    post user_session_path, params: { user: { email: user.email, password: 'testtest' } }
    assert_redirected_to users_two_factor_authentication_path
  end

  def test_otp_page_renders
    user.enable_two_factor!
    post user_session_path, params: { user: { email: user.email, password: 'testtest' } }
    get users_two_factor_authentication_path
    assert_response :success
  end

  def test_valid_otp_completes_sign_in
    user.enable_two_factor!
    post user_session_path, params: { user: { email: user.email, password: 'testtest' } }

    totp = ROTP::TOTP.new(user.otp_secret)
    post users_two_factor_authentication_path, params: { otp_attempt: totp.now }
    assert_response :redirect
  end

  def test_invalid_otp_re_renders_form
    user.enable_two_factor!
    post user_session_path, params: { user: { email: user.email, password: 'testtest' } }

    post users_two_factor_authentication_path, params: { otp_attempt: '000000' }
    assert_response :success
    assert_select '.flash-alert', text: I18n.t('two_factor.invalid_code', locale: :ja), count: 1
  end

  def test_otp_page_without_session_redirects
    get users_two_factor_authentication_path
    assert_redirected_to new_user_session_path
  end

  def test_invalid_password_redirects_to_sign_in
    post user_session_path, params: { user: { email: user.email, password: 'wrongpassword' } }
    assert_redirected_to new_user_session_path
  end

  # AUTHI18N-02: OTP page renders in Japanese (default locale)
  def test_OTPページが日本語でレンダリングされる
    user.enable_two_factor!
    post user_session_path, params: { user: { email: user.email, password: 'testtest' } }
    get users_two_factor_authentication_path
    assert_response :success
    assert_select 'html[lang=?]', 'ja'
    assert_select 'label', text: I18n.t('two_factor.code_label', locale: :ja)
  end

  # AUTHI18N-02: OTP page renders in English via Accept-Language
  def test_OTPページが英語でレンダリングされる
    user.enable_two_factor!
    post user_session_path,
      params: { user: { email: user.email, password: 'testtest' } },
      headers: { 'Accept-Language' => 'en' }
    get users_two_factor_authentication_path,
      headers: { 'Accept-Language' => 'en' }
    assert_response :success
    assert_select 'html[lang=?]', 'en'
    assert_select 'label', text: I18n.t('two_factor.code_label', locale: :en)
  end

  # I18N-02 + AUTHI18N-02: pending OTP user keeps saved English locale.
  def test_保存済みlocaleがenのユーザはOTPページを英語で表示する
    user.preference.update!(locale: 'en')
    user.enable_two_factor!

    post user_session_path, params: { user: { email: user.email, password: 'testtest' } }
    assert_redirected_to users_two_factor_authentication_path

    get users_two_factor_authentication_path
    assert_response :success
    assert_select 'html[lang=?]', 'en'
    assert_select 'label', text: I18n.t('two_factor.code_label', locale: :en)
  end

  # I18N-03: stale unsupported saved locale still falls back safely.
  def test_保存済みlocaleが未対応値のOTPページはデフォルト日本語にフォールバックする
    user.preference.update_column(:locale, 'fr')
    user.enable_two_factor!

    post user_session_path, params: { user: { email: user.email, password: 'testtest' } }
    assert_redirected_to users_two_factor_authentication_path

    get users_two_factor_authentication_path
    assert_response :success
    assert_select 'html[lang=?]', 'ja'
    assert_select 'label', text: I18n.t('two_factor.code_label', locale: :ja)
  end
end
