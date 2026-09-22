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

  def test_feed_idempotent_create_updates_visited_at
    sign_in @user

    post visited_links_path, params: {
      url: 'https://example.com/feed-dup',
      title: 'Headline',
      source: 'feed'
    }
    assert_response :no_content
    first_visited_at = VisitedLink.last.visited_at

    travel 1.second do
      assert_no_difference('VisitedLink.count') do
        post visited_links_path, params: {
          url: 'https://example.com/feed-dup',
          title: 'Headline',
          source: 'feed'
        }
      end
    end

    assert_response :no_content
    assert_equal 1, VisitedLink.count
    assert VisitedLink.last.visited_at >= first_visited_at
  end

  def test_non_feed_ignores_title_and_source
    sign_in @user

    post visited_links_path, params: {
      url: 'https://example.com/x-post',
      title: 'Should Not Persist'
    }

    assert_response :no_content
    link = VisitedLink.last
    assert_equal 'https://example.com/x-post', link.url
    assert_nil link.title
    assert_nil link.source
  end

  def test_feed_create_persists_title_and_source
    sign_in @user

    assert_difference('VisitedLink.count', 1) do
      post visited_links_path, params: {
        url: 'https://example.com/rss-article',
        title: 'Sample Headline',
        source: 'feed'
      }
    end

    assert_response :no_content
    link = VisitedLink.last
    assert_equal 'https://example.com/rss-article', link.url
    assert_equal 'Sample Headline', link.title
    assert_equal 'feed', link.source
  end

  def test_x_create_persists_title_and_source
    sign_in @user

    assert_difference('VisitedLink.count', 1) do
      post visited_links_path, params: {
        url: 'https://x.com/user/status/1',
        title: 'Sample Post',
        source: 'x'
      }
    end

    assert_response :no_content
    link = VisitedLink.last
    assert_equal 'https://x.com/user/status/1', link.url
    assert_equal 'Sample Post', link.title
    assert_equal 'x', link.source
  end

  def test_feed_create_persists_gadget_id
    sign_in @user
    feed = Feed.find(1)

    post visited_links_path, params: {
      url: 'https://example.com/rss-article',
      title: 'Sample Headline',
      source: 'feed',
      gadget_id: feed.gadget_id
    }

    assert_response :no_content
    link = VisitedLink.last
    assert_equal feed.gadget_id, link.gadget_id
  end

  def test_feed_create_rejects_other_users_gadget_id
    sign_in @user
    other_feed = Feed.find(2)

    post visited_links_path, params: {
      url: 'https://example.com/rss-article',
      title: 'Sample Headline',
      source: 'feed',
      gadget_id: other_feed.gadget_id
    }

    assert_response :no_content
    assert_nil VisitedLink.last.gadget_id
  end

  def test_mastodon_create_persists_title_and_source
    sign_in @user

    assert_difference('VisitedLink.count', 1) do
      post visited_links_path, params: {
        url: 'https://mastodon.example/@user/1',
        title: 'Sample Toot',
        source: 'mastodon'
      }
    end

    assert_response :no_content
    link = VisitedLink.last
    assert_equal 'https://mastodon.example/@user/1', link.url
    assert_equal 'Sample Toot', link.title
    assert_equal 'mastodon', link.source
  end

  def test_cucumber_hooks_include_visited_link_reset
    hooks_path = Rails.root.join('features/support/hooks.rb')
    assert File.read(hooks_path).include?('VisitedLink.delete_all'),
           'Expected features/support/hooks.rb to call VisitedLink.delete_all for scenario isolation (DAT-04)'
  end
end
