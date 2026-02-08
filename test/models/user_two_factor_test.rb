require 'test_helper'

class UserTwoFactorTest < ActiveSupport::TestCase
  def test_new_user_generates_otp_secret
    u = User.new(email: "new2fa@example.com", password: "testtest", password_confirmation: "testtest")
    u.save!
    assert u.otp_secret.present?
  end

  def test_two_factor_enabled_returns_false_by_default
    assert_not user.two_factor_enabled?
  end

  def test_enable_two_factor
    user.enable_two_factor!
    assert user.two_factor_enabled?
  end

  def test_disable_two_factor
    user.enable_two_factor!
    old_secret = user.otp_secret
    user.disable_two_factor!
    assert_not user.two_factor_enabled?
    assert_not_equal old_secret, user.reload.otp_secret
  end

  def test_validate_and_consume_otp
    totp = ROTP::TOTP.new(user.otp_secret)
    code = totp.now
    assert user.validate_and_consume_otp!(code)
  end

  def test_invalid_otp_rejected
    assert_not user.validate_and_consume_otp!('000000')
  end

  def test_otp_provisioning_uri
    uri = user.otp_provisioning_uri
    assert uri.include?('otpauth://totp/')
    assert uri.include?(ERB::Util.url_encode(user.email))
  end
end
