require 'test_helper'

class UserTest < ActiveSupport::TestCase
  def test_admin_question_mark_uses_database_flag
    u = users(:twitter_user)
    assert_not u.admin?

    u.update_columns(admin: true)
    u.reload
    assert_predicate u, :admin?
  end

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

  def test_twitter2_from_omniauth_stores_oauth2_tokens_on_existing_user
    u = users(:twitter_user)
    expires_ts = Time.now.to_i + 7200
    auth = OmniAuth::AuthHash.new(
      'provider' => 'twitter2',
      'uid' => u.uid,
      'info' => { 'name' => u.x_user_name },
      'credentials' => { 'token' => 'bearer-tok', 'refresh_token' => 'ref-tok', 'expires_at' => expires_ts, 'expires' => true }
    )
    result = User.from_omniauth(auth)
    assert_equal u.id, result.id
    u.reload
    assert_equal 'bearer-tok', u.oauth2_token
    assert_equal 'ref-tok', u.oauth2_refresh_token
    assert_in_delta expires_ts, u.oauth2_token_expires_at.to_i, 1
  end

  def test_twitter2_from_omniauth_links_existing_user_by_email_when_uid_missing
    u = users(:twitter_user)
    u.update_columns(uid: nil, provider: nil, email: 'link-by-email@example.com')
    auth = OmniAuth::AuthHash.new(
      'provider' => 'twitter2',
      'uid' => 'oauth2-uid-after-email-registration',
      'info' => { 'name' => u.x_user_name, 'email' => 'link-by-email@example.com' },
      'credentials' => { 'token' => 'bearer-tok', 'refresh_token' => 'ref-tok', 'expires_at' => Time.now.to_i + 7200, 'expires' => true }
    )
    result = User.from_omniauth(auth)
    assert_equal u.id, result.id
    u.reload
    assert_equal 'oauth2-uid-after-email-registration', u.uid
    assert_equal 'twitter2', u.provider
    assert_equal 'bearer-tok', u.oauth2_token
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
  end

  def test_twitter2_from_omniauth_updates_dummy_email_on_reauth
    u = users(:twitter_user)
    # u.email is already dummy_00000000-0000-0000-0000-000000000001@example.com
    auth = OmniAuth::AuthHash.new(
      'provider' => 'twitter2',
      'uid' => u.uid,
      'info' => { 'name' => u.x_user_name, 'email' => 'real-x-email@example.com' },
      'credentials' => { 'token' => 't', 'refresh_token' => 'r', 'expires_at' => Time.now.to_i + 3600, 'expires' => true }
    )
    User.from_omniauth(auth)
    u.reload
    assert_equal 'real-x-email@example.com', u.email
  end

  def test_twitter2_from_omniauth_does_not_overwrite_real_email_on_reauth
    u = users(:twitter_user)
    u.update_columns(email: 'already-real@example.com')
    auth = OmniAuth::AuthHash.new(
      'provider' => 'twitter2',
      'uid' => u.uid,
      'info' => { 'name' => u.x_user_name, 'email' => 'new-x-email@example.com' },
      'credentials' => { 'token' => 't', 'refresh_token' => 'r', 'expires_at' => Time.now.to_i + 3600, 'expires' => true }
    )
    User.from_omniauth(auth)
    u.reload
    assert_equal 'already-real@example.com', u.email
  end

  def test_twitter2_from_omniauth_does_not_change_email_when_x_provides_none
    u = users(:twitter_user)
    # u.email is already dummy — X sends no email
    auth = OmniAuth::AuthHash.new(
      'provider' => 'twitter2',
      'uid' => u.uid,
      'info' => { 'name' => u.x_user_name },
      'credentials' => { 'token' => 't', 'refresh_token' => 'r', 'expires_at' => Time.now.to_i + 3600, 'expires' => true }
    )
    User.from_omniauth(auth)
    u.reload
    assert_match(/\Adummy_/, u.email)
  end

  def test_oauth2_token_encrypted_at_rest
    u = users(:twitter_user)
    u.oauth2_token = 'plain-oauth2-token'
    u.save!(validate: false)
    raw = ActiveRecord::Base.connection.select_value(
      ActiveRecord::Base.sanitize_sql_array(['SELECT oauth2_token FROM users WHERE id = ?', u.id])
    )
    assert_not_equal 'plain-oauth2-token', raw
  end

  def test_destroy_account_soft_deletes_without_modifying_account_data
    u = users(:twitter_user)
    email = u.email
    x_user_name = u.x_user_name
    uid = u.uid
    provider = u.provider
    note_count = Note.where(user_id: u.id).count

    u.destroy_account!
    u.reload

    assert u.deleted?
    assert u.deleted_at.present?
    assert_equal email, u.email
    assert_equal x_user_name, u.x_user_name
    assert_equal uid, u.uid
    assert_equal provider, u.provider
    assert_equal note_count, Note.where(user_id: u.id).count
  end

  def test_active_for_authentication_false_when_deleted
    u = User.find(3)
    u.update_columns(deleted: true, deleted_at: Time.current)
    assert_not u.active_for_authentication?
  end

  def test_from_omniauth_twitter2_matches_user_after_operational_restore
    u = users(:twitter_user)
    u.update_columns(provider: 'twitter2', uid: 'restore-oauth-uid')

    u.destroy_account!
    u.reload
    assert u.deleted?

    u.update_columns(deleted: false, deleted_at: nil)

    auth = OmniAuth::AuthHash.new(
      'provider' => 'twitter2',
      'uid' => 'restore-oauth-uid',
      'info' => { 'name' => 'Changed Display Name', 'email' => 'restored@example.com' },
      'credentials' => { 'token' => 't', 'refresh_token' => 'r' }
    )

    result = User.from_omniauth(auth)
    assert_equal u.id, result.id
    assert_equal 'restored@example.com', result.email
    assert_not result.deleted?
  end

  def test_from_omniauth_google_matches_user_after_operational_restore
    u = User.create!(
      email: 'google-restore@example.com',
      password: Devise.friendly_token[0, 20]
    )

    u.destroy_account!
    u.reload
    assert u.deleted?

    u.update_columns(deleted: false, deleted_at: nil)

    auth = OmniAuth::AuthHash.new(
      'provider' => 'google_oauth2',
      'uid' => 'google-restore-uid',
      'info' => { 'email' => 'google-restore@example.com', 'name' => 'Google User' }
    )

    result = User.from_omniauth(auth)
    assert_equal u.id, result.id
    assert_not result.deleted?
  end

  def test_from_omniauth_twitter2_does_not_match_deleted_user
    u = users(:twitter_user)
    u.update_columns(provider: 'twitter2', uid: 'deleted-oauth-uid')
    u.destroy_account!

    auth = OmniAuth::AuthHash.new(
      'provider' => 'twitter2',
      'uid' => 'deleted-oauth-uid',
      'info' => { 'name' => 'New', 'email' => 'new@example.com' },
      'credentials' => { 'token' => 't', 'refresh_token' => 'r' }
    )

    assert_raise ActiveRecord::RecordNotUnique do
      User.from_omniauth(auth)
    end
  end

  def test_facebook_from_omniauth_finds_existing_user_by_email
    u = users(:one)
    auth = OmniAuth::AuthHash.new(
      'provider' => 'facebook',
      'uid' => 'fb-uid-existing',
      'info' => { 'email' => u.email, 'name' => 'FB User' }
    )
    result = User.from_omniauth(auth)
    assert_equal u.id, result.id
  end

  def test_facebook_from_omniauth_creates_new_user_when_email_unknown
    auth = OmniAuth::AuthHash.new(
      'provider' => 'facebook',
      'uid' => 'fb-uid-new',
      'info' => { 'email' => 'fb-new@example.com', 'name' => 'New FB User' }
    )
    assert_difference 'User.count', 1 do
      result = User.from_omniauth(auth)
      assert_equal 'fb-new@example.com', result.email
    end
  end

  def test_facebook_from_omniauth_raises_when_email_taken_by_deleted_user
    u = User.create!(email: 'fb-deleted@example.com', password: Devise.friendly_token[0, 20])
    u.destroy_account!

    auth = OmniAuth::AuthHash.new(
      'provider' => 'facebook',
      'uid' => 'fb-uid-deleted',
      'info' => { 'email' => 'fb-deleted@example.com', 'name' => 'Deleted FB User' }
    )
    assert_raise ActiveRecord::RecordInvalid do
      User.from_omniauth(auth)
    end
  end

  def test_stale_lock_version_raises_on_update
    u = users(:one)
    stale = User.find(u.id)
    u.update!(x_user_name: 'updated-once')
    assert_raises(ActiveRecord::StaleObjectError) do
      stale.update!(x_user_name: 'updated-twice')
    end
  end
end
