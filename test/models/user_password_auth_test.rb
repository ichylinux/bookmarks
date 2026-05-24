require 'test_helper'

class UserPasswordAuthTest < ActiveSupport::TestCase
  test "after_password_reset sets password_auth_enabled to true on password reset flow" do
    u = users(:one)
    refute u.password_auth_enabled

    # Simulate a reset token being present (as would exist after send_reset_password_instructions)
    raw_token = SecureRandom.hex(20)
    digest = Devise.token_generator.digest(User, :reset_password_token, raw_token)
    u.update_columns(reset_password_token: digest, reset_password_sent_at: 1.hour.ago)

    u.reset_password("newpassword123", "newpassword123")

    u.reload
    assert u.password_auth_enabled
  end

  test "after_password_reset is not set when creating a user with a random password" do
    u = User.create!(
      email: "newuser_#{SecureRandom.hex(4)}@example.com",
      password: Devise.friendly_token[0, 20]
    )
    refute u.password_auth_enabled
  end

  test "after_password_reset is not set when saving other attributes without a reset token" do
    u = users(:one)
    u.update_column(:password_auth_enabled, false)

    # Save without any reset token present
    u.update!(email: "changed_#{SecureRandom.hex(4)}@example.com")

    u.reload
    refute u.password_auth_enabled
  end

  test "disconnect_form_auth! sets password_auth_enabled to false" do
    u = users(:one)
    u.update_column(:password_auth_enabled, true)

    u.disconnect_form_auth!

    u.reload
    refute u.password_auth_enabled
  end

  test "disconnect_form_auth! prevents sign-in with old password" do
    u = users(:one)
    old_encrypted = u.encrypted_password

    u.disconnect_form_auth!

    u.reload
    assert_not_equal old_encrypted, u.encrypted_password
    refute u.valid_password?("password")
  end
end
