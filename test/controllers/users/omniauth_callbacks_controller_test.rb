require 'test_helper'

class Users::OmniauthCallbacksControllerTest < ActionDispatch::IntegrationTest

  setup do
    OmniAuth.config.test_mode = true
  end

  teardown do
    OmniAuth.config.mock_auth[:facebook] = nil
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
