require 'test_helper'

class UserDisconnectAuthTest < ActiveSupport::TestCase
  def setup
    @user = users(:one)
    @user.update_column(:password_auth_enabled, false)
  end

  # disconnect_oauth!

  test "disconnect_oauth! removes the identity" do
    OauthIdentity.create!(user: @user, provider: 'google_oauth2', uid: 'g1')
    OauthIdentity.create!(user: @user, provider: 'twitter2', uid: 't1')

    @user.disconnect_oauth!('google_oauth2')

    assert_nil OauthIdentity.find_by(user: @user, provider: 'google_oauth2')
    assert OauthIdentity.exists?(user: @user, provider: 'twitter2')
  end

  test "disconnect_oauth! raises LastAuthMethodError when it would remove the only auth method" do
    OauthIdentity.create!(user: @user, provider: 'google_oauth2', uid: 'g1')

    assert_raises(User::LastAuthMethodError) do
      @user.disconnect_oauth!('google_oauth2')
    end

    assert OauthIdentity.exists?(user: @user, provider: 'google_oauth2')
  end

  test "disconnect_oauth! allows removal when password auth is enabled" do
    @user.update_column(:password_auth_enabled, true)
    OauthIdentity.create!(user: @user, provider: 'google_oauth2', uid: 'g1')

    @user.disconnect_oauth!('google_oauth2')

    assert_nil OauthIdentity.find_by(user: @user, provider: 'google_oauth2')
  end

  test "disconnect_oauth! raises StaleObjectError on concurrent modification" do
    OauthIdentity.create!(user: @user, provider: 'google_oauth2', uid: 'g1')
    OauthIdentity.create!(user: @user, provider: 'twitter2', uid: 't1')

    stale_lock_version = @user.lock_version
    User.where(id: @user.id).update_all("lock_version = lock_version + 1")

    assert_raises(ActiveRecord::StaleObjectError) do
      @user.disconnect_oauth!('google_oauth2', lock_version: stale_lock_version)
    end

    assert OauthIdentity.exists?(user: @user, provider: 'google_oauth2'),
      "identity should not be deleted when stale"
  end

  # disconnect_form_auth!

  test "disconnect_form_auth! disables password auth" do
    @user.update_column(:password_auth_enabled, true)
    OauthIdentity.create!(user: @user, provider: 'google_oauth2', uid: 'g1')

    @user.disconnect_form_auth!

    refute @user.reload.password_auth_enabled?
  end

  test "disconnect_form_auth! raises LastAuthMethodError when no oauth identities" do
    @user.update_column(:password_auth_enabled, true)

    assert_raises(User::LastAuthMethodError) do
      @user.disconnect_form_auth!
    end

    assert @user.reload.password_auth_enabled?
  end

  test "disconnect_form_auth! raises StaleObjectError on concurrent modification" do
    @user.update_column(:password_auth_enabled, true)
    OauthIdentity.create!(user: @user, provider: 'google_oauth2', uid: 'g1')

    stale_lock_version = @user.lock_version
    User.where(id: @user.id).update_all("lock_version = lock_version + 1")

    assert_raises(ActiveRecord::StaleObjectError) do
      @user.disconnect_form_auth!(lock_version: stale_lock_version)
    end

    assert @user.reload.password_auth_enabled?, "password auth should not be disabled when stale"
  end
end
