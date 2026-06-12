require 'test_helper'

class Users::MastodonInstancesControllerTest < ActionDispatch::IntegrationTest
  def test_create_stores_normalized_instance_and_starts_mastodon_oauth_via_post_form
    post user_mastodon_instance_path,
      params: { instance: 'https://Mastodon.Social/' },
      headers: { 'HTTP_REFERER' => new_user_session_url }

    assert_response :success
    assert_equal 'mastodon.social', session[:mastodon_instance]
    assert_nil session[:mastodon_oauth_client_id]
    assert_select 'form#mastodon-oauth-redirect[action=?][method=post]',
      user_mastodon_omniauth_authorize_path
  end

  def test_create_rejects_invalid_instance_with_localized_flash_ja
    post user_mastodon_instance_path,
      params: { instance: 'not valid' },
      headers: { 'HTTP_REFERER' => new_user_session_url }

    assert_redirected_to new_user_session_path
    assert_nil session[:mastodon_instance]
    assert_equal I18n.t('devise.shared.omniauth.mastodon.errors.invalid', locale: :ja),
      flash[:alert]
  end

  def test_create_rejects_blank_with_localized_flash_en
    post user_mastodon_instance_path,
      params: { instance: '' },
      headers: {
        'HTTP_REFERER' => new_user_session_url,
        'Accept-Language' => 'en'
      }

    assert_redirected_to new_user_session_path
    assert_nil session[:mastodon_instance]
    assert_equal I18n.t('devise.shared.omniauth.mastodon.errors.blank', locale: :en),
      flash[:alert]
  end
end
