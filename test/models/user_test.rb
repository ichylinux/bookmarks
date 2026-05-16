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

  def test_twitter_from_omniauth_persists_credentials_on_create
    auth = OmniAuth::AuthHash.new(
      'provider' => 'twitter',
      'uid' => 'tw-uid-1',
      'info' => { 'name' => 'New Twitter Person' },
      'credentials' => { 'token' => 'oauth_t', 'secret' => 'oauth_s' }
    )
    u = User.from_omniauth(auth)
    assert u.persisted?
    u.reload
    assert_equal 'twitter', u.provider
    assert_equal 'tw-uid-1', u.uid
    assert_equal 'oauth_t', u.token
    assert_equal 'oauth_s', u.token_secret
  ensure
    User.where(name: 'New Twitter Person').delete_all
  end

  def test_twitter_from_omniauth_updates_credentials_on_reauth
    u = users(:twitter_user)
    auth = OmniAuth::AuthHash.new(
      'provider' => 'twitter',
      'uid' => u.uid,
      'info' => { 'name' => u.name },
      'credentials' => { 'token' => 'rotated_t', 'secret' => 'rotated_s' }
    )
    User.from_omniauth(auth)
    u.reload
    assert_equal 'rotated_t', u.token
    assert_equal 'rotated_s', u.token_secret
  ensure
    u.reload
    u.update_columns(
      provider: 'twitter',
      uid: 'fixture_twitter_uid',
      token: 'fixture_plain_token',
      token_secret: 'fixture_plain_secret'
    )
  end

  def test_twitter_from_omniauth_finds_existing_user_by_uid
    existing = users(:twitter_user)
    auth = OmniAuth::AuthHash.new(
      'provider' => 'twitter',
      'uid' => existing.uid,
      'info' => { 'name' => 'Different Name' },
      'credentials' => { 'token' => 'tok', 'secret' => 'sec' }
    )
    result = User.from_omniauth(auth)
    assert_equal existing.id, result.id
    assert_equal User.where(uid: existing.uid, provider: 'twitter').count, 1
  ensure
    existing.reload
    existing.update_columns(
      token: 'fixture_plain_token',
      token_secret: 'fixture_plain_secret'
    )
  end

  def test_twitter_from_omniauth_creates_user_when_uid_not_found
    auth = OmniAuth::AuthHash.new(
      'provider' => 'twitter',
      'uid' => 'brand-new-uid-999',
      'info' => { 'name' => 'Newcomer' },
      'credentials' => { 'token' => 'tok', 'secret' => 'sec' }
    )
    assert_difference 'User.count', 1 do
      User.from_omniauth(auth)
    end
  ensure
    User.where(uid: 'brand-new-uid-999', provider: 'twitter').delete_all
  end

  def test_token_encrypted_at_rest
    u = users(:twitter_user)
    u.token = 'plain-token-value'
    u.token_secret = 'plain-secret-value'
    u.save!(validate: false)
    raw = ActiveRecord::Base.connection.select_value(
      ActiveRecord::Base.sanitize_sql_array(['SELECT token FROM users WHERE id = ?', u.id])
    )
    assert_not_equal 'plain-token-value', raw
  ensure
    u = users(:twitter_user)
    u.update_columns(
      token: 'fixture_plain_token',
      token_secret: 'fixture_plain_secret'
    )
  end
end
