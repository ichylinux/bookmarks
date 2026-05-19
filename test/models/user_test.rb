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

  def test_twitter2_from_omniauth_stores_oauth2_tokens_on_existing_user
    u = users(:twitter_user)
    expires_ts = Time.now.to_i + 7200
    auth = OmniAuth::AuthHash.new(
      'provider' => 'twitter2',
      'uid' => u.uid,
      'info' => { 'name' => u.name },
      'credentials' => { 'token' => 'bearer-tok', 'refresh_token' => 'ref-tok', 'expires_at' => expires_ts, 'expires' => true }
    )
    result = User.from_omniauth(auth)
    assert_equal u.id, result.id
    u.reload
    assert_equal 'bearer-tok', u.oauth2_token
    assert_equal 'ref-tok', u.oauth2_refresh_token
    assert_in_delta expires_ts, u.oauth2_token_expires_at.to_i, 1
  ensure
    u = users(:twitter_user)
    u.update_columns(oauth2_token: nil, oauth2_refresh_token: nil, oauth2_token_expires_at: nil)
  end

  def test_twitter2_from_omniauth_creates_new_user_when_uid_unknown
    auth = OmniAuth::AuthHash.new(
      'provider' => 'twitter2',
      'uid' => 'brand-new-oauth2-uid',
      'info' => { 'name' => 'OAuth2 Newcomer' },
      'credentials' => { 'token' => 'bearer-tok', 'refresh_token' => 'ref-tok', 'expires_at' => Time.now.to_i + 7200, 'expires' => true }
    )
    assert_difference 'User.count', 1 do
      User.from_omniauth(auth)
    end
  ensure
    User.where(uid: 'brand-new-oauth2-uid', provider: 'twitter2').delete_all
  end

  def test_twitter2_from_omniauth_creates_new_user_with_email_when_provided
    auth = OmniAuth::AuthHash.new(
      'provider' => 'twitter2',
      'uid' => 'brand-new-oauth2-uid-with-email',
      'info' => { 'name' => 'OAuth2 Emailer', 'email' => 'twitter-user@example.com' },
      'credentials' => { 'token' => 'bearer-tok', 'refresh_token' => 'ref-tok', 'expires_at' => Time.now.to_i + 7200, 'expires' => true }
    )
    result = nil
    assert_difference 'User.count', 1 do
      result = User.from_omniauth(auth)
    end
    assert_equal 'twitter-user@example.com', result.email
  ensure
    User.where(uid: 'brand-new-oauth2-uid-with-email', provider: 'twitter2').delete_all
  end

  def test_twitter2_from_omniauth_updates_dummy_email_on_reauth
    u = users(:twitter_user)
    # u.email is already dummy_00000000-0000-0000-0000-000000000001@example.com
    auth = OmniAuth::AuthHash.new(
      'provider' => 'twitter2',
      'uid' => u.uid,
      'info' => { 'name' => u.name, 'email' => 'real-x-email@example.com' },
      'credentials' => { 'token' => 't', 'refresh_token' => 'r', 'expires_at' => Time.now.to_i + 3600, 'expires' => true }
    )
    User.from_omniauth(auth)
    u.reload
    assert_equal 'real-x-email@example.com', u.email
  ensure
    u = users(:twitter_user)
    u.update_columns(
      email: 'dummy_00000000-0000-0000-0000-000000000001@example.com',
      oauth2_token: nil, oauth2_refresh_token: nil, oauth2_token_expires_at: nil
    )
  end

  def test_twitter2_from_omniauth_does_not_overwrite_real_email_on_reauth
    u = users(:twitter_user)
    u.update_columns(email: 'already-real@example.com')
    auth = OmniAuth::AuthHash.new(
      'provider' => 'twitter2',
      'uid' => u.uid,
      'info' => { 'name' => u.name, 'email' => 'new-x-email@example.com' },
      'credentials' => { 'token' => 't', 'refresh_token' => 'r', 'expires_at' => Time.now.to_i + 3600, 'expires' => true }
    )
    User.from_omniauth(auth)
    u.reload
    assert_equal 'already-real@example.com', u.email
  ensure
    u = users(:twitter_user)
    u.update_columns(
      email: 'dummy_00000000-0000-0000-0000-000000000001@example.com',
      oauth2_token: nil, oauth2_refresh_token: nil, oauth2_token_expires_at: nil
    )
  end

  def test_twitter2_from_omniauth_does_not_change_email_when_x_provides_none
    u = users(:twitter_user)
    # u.email is already dummy — X sends no email
    auth = OmniAuth::AuthHash.new(
      'provider' => 'twitter2',
      'uid' => u.uid,
      'info' => { 'name' => u.name },
      'credentials' => { 'token' => 't', 'refresh_token' => 'r', 'expires_at' => Time.now.to_i + 3600, 'expires' => true }
    )
    User.from_omniauth(auth)
    u.reload
    assert_match(/\Adummy_/, u.email)
  ensure
    u = users(:twitter_user)
    u.update_columns(
      email: 'dummy_00000000-0000-0000-0000-000000000001@example.com',
      oauth2_token: nil, oauth2_refresh_token: nil, oauth2_token_expires_at: nil
    )
  end

  def test_oauth2_token_encrypted_at_rest
    u = users(:twitter_user)
    u.oauth2_token = 'plain-oauth2-token'
    u.save!(validate: false)
    raw = ActiveRecord::Base.connection.select_value(
      ActiveRecord::Base.sanitize_sql_array(['SELECT oauth2_token FROM users WHERE id = ?', u.id])
    )
    assert_not_equal 'plain-oauth2-token', raw
  ensure
    u = users(:twitter_user)
    u.update_columns(oauth2_token: nil)
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
