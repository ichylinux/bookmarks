require 'test_helper'

class FeedArticleHistoriesControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = User.find(1)
    @other_user = User.find(2)
    VisitedLink.delete_all
  end

  def test_index_success
    sign_in @user
    get feed_article_histories_path
    assert_response :success
  end

  def test_index_shows_feed_title
    sign_in @user
    VisitedLink.record!(@user, 'https://example.com/feed-a', title: 'Feed Headline', source: 'feed')

    get feed_article_histories_path

    assert_response :success
    assert_includes response.body, 'Feed Headline'
  end

  def test_index_excludes_non_feed_rows
    sign_in @user
    VisitedLink.record!(@user, 'https://example.com/feed-a', title: 'Feed Headline', source: 'feed')
    VisitedLink.record!(@user, 'https://example.com/mastodon', title: 'Mastodon Post', source: 'mastodon')

    get feed_article_histories_path

    assert_response :success
    assert_includes response.body, 'Feed Headline'
    assert_not_includes response.body, 'Mastodon Post'
  end

  def test_index_orders_newest_first
    sign_in @user
    VisitedLink.record!(@user, 'https://example.com/older', title: 'Older Article', source: 'feed')

    travel 1.second do
      VisitedLink.record!(@user, 'https://example.com/newer', title: 'Newer Article', source: 'feed')
    end

    get feed_article_histories_path

    assert_response :success
    assert_operator response.body.index('Newer Article'), :<, response.body.index('Older Article')
  end

  def test_index_empty_state
    sign_in @user
    get feed_article_histories_path

    assert_response :success
    assert_includes response.body, I18n.t('feed_article_histories.index.empty')
  end

  def test_index_excludes_other_user_rows
    sign_in @user
    VisitedLink.record!(@other_user, 'https://example.com/other', title: 'Other User Article', source: 'feed')

    get feed_article_histories_path

    assert_response :success
    assert_not_includes response.body, 'Other User Article'
  end

  def test_unauthenticated_redirects_to_sign_in
    get feed_article_histories_path

    assert_response :redirect
    assert_redirected_to new_user_session_path
  end
end
