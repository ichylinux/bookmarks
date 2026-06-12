require 'test_helper'

class OauthIdentitiesControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = users(:one)
  end

  def test_destroy_requires_authentication
    delete oauth_identity_path('google_oauth2')
    assert_redirected_to new_user_session_path
  end

  def test_destroy_disconnects_provider_and_redirects
    sign_in_and_sync
    OauthIdentity.create!(user: @user, provider: 'google_oauth2', uid: 'g123')
    OauthIdentity.create!(user: @user, provider: 'twitter2', uid: 't456')

    assert_difference 'OauthIdentity.count', -1 do
      delete oauth_identity_path('google_oauth2'), params: { lock_version: @user.lock_version }
    end

    assert_redirected_to preferences_path
    assert_equal I18n.t('oauth_identities.destroy.success', provider: 'google_oauth2', locale: :ja),
                 flash[:notice]
    assert_nil OauthIdentity.find_by(user: @user, provider: 'google_oauth2')
  end

  def test_destroy_blocks_disconnect_of_last_auth_method
    sign_in_and_sync
    @user.update_column(:password_auth_enabled, false)
    OauthIdentity.create!(user: @user, provider: 'google_oauth2', uid: 'g123')

    assert_no_difference 'OauthIdentity.count' do
      delete oauth_identity_path('google_oauth2'), params: { lock_version: @user.lock_version }
    end

    assert_redirected_to preferences_path
    assert_equal I18n.t('oauth_identities.destroy.last_auth_method', locale: :ja), flash[:alert]
  end

  def test_destroy_blocks_disconnect_of_last_auth_method_for_mastodon
    sign_in_and_sync
    @user.update_column(:password_auth_enabled, false)
    OauthIdentity.create!(user: @user, provider: 'mastodon', uid: 'mastodon.social:ca_masto_uid')

    assert_no_difference 'OauthIdentity.count' do
      delete oauth_identity_path('mastodon'), params: { lock_version: @user.lock_version }
    end

    assert_redirected_to preferences_path
    assert_equal I18n.t('oauth_identities.destroy.last_auth_method', locale: :ja), flash[:alert]
  end

  def test_destroy_allows_disconnect_when_password_auth_enabled
    sign_in_and_sync
    @user.update_column(:password_auth_enabled, true)
    OauthIdentity.create!(user: @user, provider: 'google_oauth2', uid: 'g123')

    assert_difference 'OauthIdentity.count', -1 do
      delete oauth_identity_path('google_oauth2'), params: { lock_version: @user.lock_version }
    end

    assert_redirected_to preferences_path
  end

  def test_destroy_handles_unlinked_provider_gracefully
    sign_in @user

    assert_no_difference 'OauthIdentity.count' do
      delete oauth_identity_path('facebook')
    end

    assert_redirected_to preferences_path
    assert_equal I18n.t('oauth_identities.destroy.not_connected', locale: :ja), flash[:notice]
  end

  def test_destroy_form_auth_disconnects_when_oauth_linked
    sign_in_and_sync
    @user.update_column(:password_auth_enabled, true)
    OauthIdentity.create!(user: @user, provider: 'google_oauth2', uid: 'g123')

    delete oauth_identity_path('form'), params: { lock_version: @user.lock_version }

    assert_redirected_to preferences_path
    assert_equal I18n.t('oauth_identities.destroy.success', provider: 'form', locale: :ja), flash[:notice]
    @user.reload
    refute @user.password_auth_enabled?
  end

  def test_destroy_form_auth_blocks_when_last_auth_method
    sign_in_and_sync
    @user.update_column(:password_auth_enabled, true)

    delete oauth_identity_path('form'), params: { lock_version: @user.lock_version }

    assert_redirected_to preferences_path
    assert_equal I18n.t('oauth_identities.destroy.last_auth_method', locale: :ja), flash[:alert]
    assert @user.reload.password_auth_enabled?
  end

  def test_destroy_form_auth_handles_already_disabled
    sign_in @user
    @user.update_column(:password_auth_enabled, false)
    OauthIdentity.create!(user: @user, provider: 'google_oauth2', uid: 'g123')

    delete oauth_identity_path('form')

    assert_redirected_to preferences_path
    assert_equal I18n.t('oauth_identities.destroy.not_connected', locale: :ja), flash[:notice]
  end

  def test_destroy_shows_stale_alert_on_concurrent_modification
    sign_in_and_sync
    @user.update_column(:password_auth_enabled, false)
    OauthIdentity.create!(user: @user, provider: 'google_oauth2', uid: 'g123')
    OauthIdentity.create!(user: @user, provider: 'twitter2', uid: 't456')

    stale_lock_version = @user.lock_version
    User.where(id: @user.id).update_all("lock_version = lock_version + 1")
    @user.reload

    assert_no_difference 'OauthIdentity.count' do
      delete oauth_identity_path('google_oauth2'), params: { lock_version: stale_lock_version }
    end

    assert_redirected_to preferences_path
    assert_equal I18n.t('oauth_identities.destroy.stale', locale: :ja), flash[:alert]
  end

  def test_destroy_form_auth_shows_stale_alert_on_concurrent_modification
    sign_in_and_sync
    @user.update_column(:password_auth_enabled, true)
    OauthIdentity.create!(user: @user, provider: 'google_oauth2', uid: 'g123')

    stale_lock_version = @user.lock_version
    User.where(id: @user.id).update_all("lock_version = lock_version + 1")
    @user.reload

    delete oauth_identity_path('form'), params: { lock_version: stale_lock_version }

    assert_redirected_to preferences_path
    assert_equal I18n.t('oauth_identities.destroy.stale', locale: :ja), flash[:alert]
    assert @user.reload.password_auth_enabled?
  end

  private

  # Triggers Devise Trackable (which runs on the first request after sign_in in Warden test
  # mode) so that subsequent requests use the stable post-trackable lock_version.
  def sign_in_and_sync
    sign_in @user
    get preferences_path
    @user.reload
  end
end
