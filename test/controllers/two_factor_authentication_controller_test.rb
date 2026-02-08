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
  end

  def test_otp_page_without_session_redirects
    get users_two_factor_authentication_path
    assert_redirected_to new_user_session_path
  end

  def test_invalid_password_redirects_to_sign_in
    post user_session_path, params: { user: { email: user.email, password: 'wrongpassword' } }
    assert_redirected_to new_user_session_path
  end
end
