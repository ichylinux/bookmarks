require 'test_helper'

class Users::OmniauthCallbacksControllerTest < ActionDispatch::IntegrationTest

  setup do
    Rails.application.routes.routes if OmniAuth.config.path_prefix.nil?
    OmniAuth.config.test_mode = true
  end

  teardown do
    OmniAuth.config.mock_auth[:facebook] = nil
    OmniAuth.config.mock_auth[:mastodon] = nil
    OmniAuth.config.test_mode = false
  end

  def test_facebook_callback_signs_in_persisted_user
    u = users(:one)
    OmniAuth.config.mock_auth[:facebook] = OmniAuth::AuthHash.new(
      'provider' => 'facebook',
      'uid' => 'fb-controller-uid',
      'info' => { 'email' => u.email, 'name' => 'FB User' }
    )
    get '/users/auth/facebook/callback'
    assert_response :redirect
    assert_nil flash[:alert]
    assert_equal u.id, session["warden.user.user.key"]&.first&.first
  end

  def test_mastodon_callback_signs_in_new_user
    OmniAuth.config.mock_auth[:mastodon] = OmniAuth::AuthHash.new(
      'provider' => 'mastodon',
      'uid' => 'mastodon-callback-uid',
      'info' => { 'name' => 'Masto User', 'instance' => 'mastodon.social' }
    )
    assert_difference 'User.count', 1 do
      get '/users/auth/mastodon/callback'
    end
    assert_response :redirect
    assert_nil flash[:alert]
    user = OauthIdentity.find_by(provider: 'mastodon', uid: 'mastodon.social:mastodon-callback-uid')&.user
    assert_not_nil user
    assert_equal user.id, session["warden.user.user.key"]&.first&.first
  end

  def test_facebook_callback_redirects_to_registration_when_create_fails
    # Use an email already taken by a soft-deleted user to force User.create! failure
    u = users(:one)
    u.update_columns(deleted: true)
    OmniAuth.config.mock_auth[:facebook] = OmniAuth::AuthHash.new(
      'provider' => 'facebook',
      'uid' => 'fb-fail-uid',
      'info' => { 'email' => u.email, 'name' => 'FB User' }
    )
    get '/users/auth/facebook/callback'
    assert_redirected_to new_user_registration_url
  end

end
