require 'test_helper'

class VisitedLinkTest < ActiveSupport::TestCase
  def setup
    @user = User.find(1)
    @other_user = User.find(2)
    VisitedLink.delete_all
  end

  # normalize_url

  def test_normalize_url_no_change_when_no_fragment
    assert_equal 'https://example.com/page', VisitedLink.normalize_url('https://example.com/page')
  end

  def test_normalize_url_strips_fragment
    assert_equal 'https://example.com/page', VisitedLink.normalize_url('https://example.com/page#section')
  end

  def test_normalize_url_strips_fragment_with_query_like_string_after_hash
    assert_equal 'https://example.com/page', VisitedLink.normalize_url('https://example.com/page#section?still=a-fragment')
  end

  def test_normalize_url_nil_returns_empty_string
    assert_equal '', VisitedLink.normalize_url(nil)
  end

  # record!

  def test_record_inserts_row
    assert_difference -> { VisitedLink.count }, 1 do
      VisitedLink.record!(@user, 'https://example.com')
    end
  end

  def test_record_is_idempotent
    VisitedLink.record!(@user, 'https://example.com')
    assert_no_difference -> { VisitedLink.count } do
      VisitedLink.record!(@user, 'https://example.com')
    end
  end

  def test_record_stores_normalized_url
    VisitedLink.record!(@user, 'https://example.com/page#frag')
    stored = VisitedLink.where(user_id: @user.id).pluck(:url)
    assert_equal ['https://example.com/page'], stored
  end

  def test_record_blank_url_is_noop
    assert_no_difference -> { VisitedLink.count } do
      VisitedLink.record!(@user, '')
    end
  end

  def test_record_nil_url_is_noop
    assert_no_difference -> { VisitedLink.count } do
      VisitedLink.record!(@user, nil)
    end
  end

  def test_feed_record_updates_visited_at_and_title_without_duplicate
    VisitedLink.record!(@user, 'https://example.com/feed-item', title: 'First Title', source: 'feed')
    first = VisitedLink.find_by!(user_id: @user.id, url: 'https://example.com/feed-item')
    first_visited_at = first.visited_at

    travel 1.second do
      assert_no_difference -> { VisitedLink.count } do
        VisitedLink.record!(@user, 'https://example.com/feed-item', title: 'Updated Title', source: 'feed')
      end
    end

    first.reload
    assert first.visited_at > first_visited_at
    assert_equal 'Updated Title', first.title
    assert_equal 'feed', first.source
  end

  def test_non_history_source_does_not_persist_title_or_source
    VisitedLink.record!(@user, 'https://example.com/other', title: 'Ignored', source: 'bookmark')
    link = VisitedLink.find_by!(user_id: @user.id, url: 'https://example.com/other')
    assert_nil link.title
    assert_nil link.source
  end

  def test_feed_record_empty_title_preserves_existing_title
    VisitedLink.record!(@user, 'https://example.com/feed-item', title: 'First Title', source: 'feed')

    assert_no_difference -> { VisitedLink.count } do
      VisitedLink.record!(@user, 'https://example.com/feed-item', title: '   ', source: 'feed')
    end

    link = VisitedLink.find_by!(user_id: @user.id, url: 'https://example.com/feed-item')
    assert_equal 'First Title', link.title
    assert_equal 'feed', link.source
  end

  def test_url_only_row_upgraded_on_feed_visit
    VisitedLink.record!(@user, 'https://example.com/article')

    assert_no_difference -> { VisitedLink.count } do
      VisitedLink.record!(@user, 'https://example.com/article', title: 'Feed Headline', source: 'feed')
    end

    link = VisitedLink.find_by!(user_id: @user.id, url: 'https://example.com/article')
    assert_equal 'Feed Headline', link.title
    assert_equal 'feed', link.source
  end

  def test_feed_record_truncates_overlong_title
    long_title = 'a' * 3000
    VisitedLink.record!(@user, 'https://example.com/long', title: long_title, source: 'feed')

    link = VisitedLink.find_by!(user_id: @user.id, url: 'https://example.com/long')
    assert_equal 2083, link.title.length
    assert_equal 'a' * 2083, link.title
  end

  def test_x_record_persists_title_and_source
    VisitedLink.record!(@user, 'https://x.com/user/status/1', title: 'Sample Post', source: 'x')

    link = VisitedLink.find_by!(user_id: @user.id, url: 'https://x.com/user/status/1')
    assert_equal 'Sample Post', link.title
    assert_equal 'x', link.source
  end

  def test_mastodon_record_persists_title_and_source
    VisitedLink.record!(@user, 'https://mastodon.example/@user/1', title: 'Sample Toot', source: 'mastodon')

    link = VisitedLink.find_by!(user_id: @user.id, url: 'https://mastodon.example/@user/1')
    assert_equal 'Sample Toot', link.title
    assert_equal 'mastodon', link.source
  end

  def test_feed_history_for_includes_feed_x_and_mastodon_rows
    VisitedLink.record!(@user, 'https://example.com/feed-a', title: 'Feed Item', source: 'feed')
    VisitedLink.record!(@user, 'https://x.com/user/status/1', title: 'X Post', source: 'x')
    VisitedLink.record!(@user, 'https://mastodon.example/@user/1', title: 'Mastodon Post', source: 'mastodon')
    VisitedLink.record!(@user, 'https://example.com/url-only')

    titles = VisitedLink.feed_history_for(@user).map(&:title)

    assert_includes titles, 'Feed Item'
    assert_includes titles, 'X Post'
    assert_includes titles, 'Mastodon Post'
    assert_equal 3, titles.length
  end

  # urls_for

  def test_urls_for_returns_set
    VisitedLink.record!(@user, 'https://example.com')
    result = VisitedLink.urls_for(@user)
    assert_instance_of Set, result
  end

  def test_urls_for_excludes_other_user
    VisitedLink.record!(@user, 'https://example.com')
    VisitedLink.record!(@other_user, 'https://other.com')
    result = VisitedLink.urls_for(@user)
    assert_includes result, 'https://example.com'
    assert_not_includes result, 'https://other.com'
  end

  def test_urls_for_empty_when_no_visits
    result = VisitedLink.urls_for(@user)
    assert_instance_of Set, result
    assert result.empty?
  end
end
