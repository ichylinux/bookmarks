require 'test_helper'

class UserTest < ActiveSupport::TestCase
  def test_dummy_email_rejected_on_update
    u = users(:twitter_user)
    u.email = "dummy_00000000-0000-0000-0000-000000000099@example.com"
    u.valid?
    assert u.errors[:email].present?
  end

  def test_malformed_email_rejected_on_update
    u = users(:twitter_user)
    u.email = "not-an-email"
    u.valid?
    assert u.errors[:email].present?
  end

  def test_valid_real_email_accepted_on_update
    u = users(:twitter_user)
    u.email = "real@example.com"
    u.valid?
    assert u.errors[:email].empty?
  end

  def test_dummy_email_allowed_on_create
    u = User.new(
      email: "dummy_00000000-0000-0000-0000-000000000099@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
    u.valid?
    assert u.errors[:email].empty?
  end
end
