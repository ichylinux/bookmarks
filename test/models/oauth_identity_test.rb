require 'test_helper'

class OauthIdentityTest < ActiveSupport::TestCase
  def setup
    @user = users(:one)
  end

  def test_validates_provider_presence
    identity = OauthIdentity.new(user: @user, uid: 'uid123')
    assert_not identity.valid?
    assert identity.errors[:provider].present?
  end

  def test_validates_uid_presence
    identity = OauthIdentity.new(user: @user, provider: 'google_oauth2')
    assert_not identity.valid?
    assert identity.errors[:uid].present?
  end

  def test_validates_provider_uniqueness_scoped_to_user
    OauthIdentity.create!(user: @user, provider: 'google_oauth2', uid: 'uid-abc')
    duplicate = OauthIdentity.new(user: @user, provider: 'google_oauth2', uid: 'uid-xyz')
    assert_not duplicate.valid?
    assert duplicate.errors[:provider].present?
  end

  def test_allows_same_provider_for_different_users
    user2 = users(:two)
    OauthIdentity.create!(user: @user, provider: 'google_oauth2', uid: 'uid-abc')
    identity2 = OauthIdentity.new(user: user2, provider: 'google_oauth2', uid: 'uid-def')
    assert identity2.valid?
  end

  def test_upsert_for_creates_new_identity
    assert_difference 'OauthIdentity.count', 1 do
      OauthIdentity.upsert_for!(user: @user, provider: 'google_oauth2', uid: 'google-uid-123')
    end
    identity = OauthIdentity.find_by(user: @user, provider: 'google_oauth2')
    assert_equal 'google-uid-123', identity.uid
  end

  def test_upsert_for_updates_uid_on_existing_identity
    OauthIdentity.create!(user: @user, provider: 'google_oauth2', uid: 'old-uid')
    assert_no_difference 'OauthIdentity.count' do
      OauthIdentity.upsert_for!(user: @user, provider: 'google_oauth2', uid: 'new-uid')
    end
    assert_equal 'new-uid', OauthIdentity.find_by(user: @user, provider: 'google_oauth2').uid
  end

  def test_twitter2_from_omniauth_creates_identity
    auth = OmniAuth::AuthHash.new(
      'provider' => 'twitter2',
      'uid' => 'new-twitter-uid-999',
      'info' => { 'name' => 'New Twitter User' },
      'credentials' => { 'token' => 'tok', 'refresh_token' => 'ref', 'expires_at' => Time.now.to_i + 7200, 'expires' => true }
    )
    assert_difference 'OauthIdentity.count', 1 do
      User.from_omniauth(auth)
    end
    user = User.find_by(uid: 'new-twitter-uid-999')
    identity = OauthIdentity.find_by(user: user, provider: 'twitter2')
    assert_not_nil identity
    assert_equal 'new-twitter-uid-999', identity.uid
  end

  def test_facebook_from_omniauth_creates_identity
    auth = OmniAuth::AuthHash.new(
      'provider' => 'facebook',
      'uid' => 'fb-uid-123',
      'info' => { 'email' => 'fbuser_unique_phase114@example.com' }
    )
    assert_difference 'OauthIdentity.count', 1 do
      User.from_omniauth(auth)
    end
    user = User.find_by(email: 'fbuser_unique_phase114@example.com')
    identity = OauthIdentity.find_by(user: user, provider: 'facebook')
    assert_not_nil identity
    assert_equal 'fb-uid-123', identity.uid
  end

  def test_mastodon_from_omniauth_creates_identity_with_composite_uid
    auth = OmniAuth::AuthHash.new(
      'provider' => 'mastodon',
      'uid' => '12345',
      'info' => { 'name' => 'Alice', 'nickname' => 'alice', 'instance' => 'mastodon.social' }
    )
    assert_difference 'OauthIdentity.count', 1 do
      User.from_omniauth(auth)
    end
    identity = OauthIdentity.find_by(provider: 'mastodon', uid: 'mastodon.social:12345')
    assert_not_nil identity
    user = identity.user
    assert_match(/\Adummy_.+@example\.com\z/, user.email)
  end

  def test_mastodon_from_omniauth_reauth_finds_existing_user_and_upserts
    auth = OmniAuth::AuthHash.new(
      'provider' => 'mastodon',
      'uid' => '99999',
      'info' => { 'name' => 'Bob', 'nickname' => 'bob', 'instance' => 'ruby.social' }
    )
    user = User.from_omniauth(auth)
    composite_uid = 'ruby.social:99999'

    assert_no_difference 'User.count' do
      assert_no_difference 'OauthIdentity.count' do
        result = User.from_omniauth(auth)
        assert_equal user.id, result.id
      end
    end
    assert_equal composite_uid, OauthIdentity.find_by(user: user, provider: 'mastodon').uid
  end

  def test_mastodon_from_omniauth_finds_user_by_registered_handle
    existing = users(:one)
    existing.update!(mastodon_handle: 'alice@mastodon.social')

    auth = OmniAuth::AuthHash.new(
      'provider' => 'mastodon',
      'uid' => '54321',
      'info' => { 'name' => 'Alice', 'nickname' => 'alice', 'instance' => 'mastodon.social' }
    )

    assert_no_difference 'User.count' do
      result = User.from_omniauth(auth)
      assert_equal existing.id, result.id
    end
    identity = OauthIdentity.find_by(user: existing, provider: 'mastodon')
    assert_equal 'mastodon.social:54321', identity.uid
  end

  def test_mastodon_from_omniauth_rejects_handle_squatting_on_instance_mismatch
    existing = users(:one)
    existing.update!(mastodon_handle: 'alice@mastodon.social')

    auth = OmniAuth::AuthHash.new(
      'provider' => 'mastodon',
      'uid' => '77777',
      'info' => { 'name' => 'Alice', 'nickname' => 'alice', 'instance' => 'ruby.social' }
    )

    assert_difference 'User.count', 1 do
      result = User.from_omniauth(auth)
      refute_equal existing.id, result.id
    end
  end

  def test_mastodon_from_omniauth_rejects_handle_squatting_on_username_mismatch
    existing = users(:one)
    existing.update!(mastodon_handle: 'alice@mastodon.social')

    auth = OmniAuth::AuthHash.new(
      'provider' => 'mastodon',
      'uid' => '88888',
      'info' => { 'name' => 'Bob', 'nickname' => 'bob', 'instance' => 'mastodon.social' }
    )

    assert_difference 'User.count', 1 do
      result = User.from_omniauth(auth)
      refute_equal existing.id, result.id
    end
  end

  def test_mastodon_from_omniauth_excludes_soft_deleted_user_from_handle_lookup
    existing = users(:one)
    existing.update!(mastodon_handle: 'alice@mastodon.social', deleted: true, deleted_at: Time.current)

    auth = OmniAuth::AuthHash.new(
      'provider' => 'mastodon',
      'uid' => '11111',
      'info' => { 'name' => 'Alice', 'nickname' => 'alice', 'instance' => 'mastodon.social' }
    )

    assert_difference 'User.count', 1 do
      User.from_omniauth(auth)
    end
  end

  def test_google_from_omniauth_creates_identity
    auth = OmniAuth::AuthHash.new(
      'provider' => 'google_oauth2',
      'uid' => 'google-uid-456',
      'info' => { 'email' => 'googleuser_unique_phase114@example.com' }
    )
    assert_difference 'OauthIdentity.count', 1 do
      User.from_omniauth(auth)
    end
    user = User.find_by(email: 'googleuser_unique_phase114@example.com')
    identity = OauthIdentity.find_by(user: user, provider: 'google_oauth2')
    assert_not_nil identity
    assert_equal 'google-uid-456', identity.uid
  end

  def test_backfill_idempotency
    OauthIdentity.create!(user: @user, provider: 'twitter2', uid: 'some-uid')
    initial_count = OauthIdentity.count
    # Simulating re-run: find_or_create_by should not create duplicates
    OauthIdentity.find_or_create_by!(user_id: @user.id, provider: 'twitter2') do |i|
      i.uid = 'some-uid'
    end
    assert_equal initial_count, OauthIdentity.count
  end
end
