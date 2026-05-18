require 'test_helper'

class VisitedLinksControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = User.find(1)
    VisitedLink.delete_all
  end

  def test_successful_create
    sign_in @user

    assert_difference('VisitedLink.count', 1) do
      post visited_links_path, params: { url: 'https://example.com/article' }
    end

    assert_response :no_content
  end

  def test_idempotent_create
    sign_in @user

    post visited_links_path, params: { url: 'https://example.com/article' }
    assert_response :no_content

    assert_no_difference('VisitedLink.count') do
      post visited_links_path, params: { url: 'https://example.com/article' }
    end

    assert_response :no_content
    assert_equal 1, VisitedLink.count
  end

  def test_unauthenticated_redirects_to_sign_in
    assert_no_difference('VisitedLink.count') do
      post visited_links_path, params: { url: 'https://example.com' }
    end

    assert_response :redirect
    assert_redirected_to new_user_session_path
  end

  def test_url_stored_normalized
    sign_in @user

    post visited_links_path, params: { url: 'https://example.com/page#section' }

    assert_response :no_content
    assert_equal 'https://example.com/page', VisitedLink.last.url
  end

  def test_routing_post_visited_links
    assert_routing({ path: '/visited_links', method: :post }, { controller: 'visited_links', action: 'create' })
  end
end
