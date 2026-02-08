require 'test_helper'

class TwoFactorSetupControllerTest < ActionDispatch::IntegrationTest
  def test_show_renders_setup_when_2fa_disabled
    sign_in user
    get users_two_factor_setup_path
    assert_response :success
    assert_match 'QRコード', response.body
  end

  def test_show_renders_enabled_when_2fa_enabled
    user.enable_two_factor!
    sign_in user
    get users_two_factor_setup_path
    assert_response :success
    assert_match I18n.t('two_factor.status_enabled'), response.body
  end

  def test_show_regenerates_otp_secret
    sign_in user
    old_secret = user.otp_secret
    get users_two_factor_setup_path
    assert_not_equal old_secret, user.reload.otp_secret
  end

  def test_enable_with_valid_otp
    sign_in user
    get users_two_factor_setup_path

    totp = ROTP::TOTP.new(user.reload.otp_secret)
    post users_two_factor_setup_path, params: { otp_attempt: totp.now }
    assert_redirected_to users_two_factor_setup_path
    assert user.reload.two_factor_enabled?
  end

  def test_enable_with_invalid_otp
    sign_in user
    get users_two_factor_setup_path

    post users_two_factor_setup_path, params: { otp_attempt: '000000' }
    assert_response :success
    assert_not user.reload.two_factor_enabled?
  end

  def test_disable
    user.enable_two_factor!
    sign_in user
    old_secret = user.otp_secret

    delete users_two_factor_setup_path
    assert_redirected_to users_two_factor_setup_path
    assert_not user.reload.two_factor_enabled?
    assert_not_equal old_secret, user.reload.otp_secret
  end

  def test_requires_authentication
    get users_two_factor_setup_path
    assert_response :redirect
  end
end
