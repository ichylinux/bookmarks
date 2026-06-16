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
      'info' => { 'name' => 'Masto User', 'nickname' => 'masto', 'instance' => 'mastodon.social' }
    )
    assert_difference 'User.count', 1 do
      get '/users/auth/mastodon/callback'
    end
    assert_response :redirect
    assert_nil flash[:alert]
    user = OauthIdentity.find_by(provider: 'mastodon', uid: 'mastodon.social:mastodon-callback-uid')&.user
    assert_not_nil user
    assert_equal user.id, session["warden.user.user.key"]&.first&.first
    assert_nil session[:mastodon_instance]
  end

  def test_mastodon_callback_signs_in_user_by_registered_handle
    existing = users(:one)
    existing.update!(mastodon_handle: 'alice@mastodon.social')

    OmniAuth.config.mock_auth[:mastodon] = OmniAuth::AuthHash.new(
      'provider' => 'mastodon',
      'uid' => '54321',
      'info' => { 'name' => 'Alice', 'nickname' => 'alice', 'instance' => 'mastodon.social' }
    )

    assert_no_difference 'User.count' do
      get '/users/auth/mastodon/callback'
    end

    assert_response :redirect
    follow_redirect!
    assert_equal existing.id, session["warden.user.user.key"]&.first&.first
    assert_equal 'mastodon.social:54321', OauthIdentity.find_by(user: existing, provider: 'mastodon').uid
  end

  def test_mastodon_callback_uses_extra_instance_when_info_instance_missing
    existing = users(:two)
    existing.update!(mastodon_handle: 'bob@ruby.social')

    OmniAuth.config.mock_auth[:mastodon] = OmniAuth::AuthHash.new(
      'provider' => 'mastodon',
      'uid' => '77777',
      'info' => { 'name' => 'Bob', 'nickname' => 'bob' },
      'extra' => { 'instance' => 'ruby.social' }
    )

    assert_no_difference 'User.count' do
      get '/users/auth/mastodon/callback'
    end

    assert_equal existing.id, session["warden.user.user.key"]&.first&.first
    assert_equal 'ruby.social:77777', OauthIdentity.find_by(user: existing, provider: 'mastodon').uid
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
