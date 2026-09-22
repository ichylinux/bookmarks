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

  def test_feed_record_persists_gadget_id_for_owned_feed
    feed = Feed.find(1)
    VisitedLink.record!(@user, 'https://example.com/feed-item', title: 'Headline', source: 'feed',
                      gadget_id: feed.gadget_id)

    link = VisitedLink.find_by!(user_id: @user.id, url: 'https://example.com/feed-item')
    assert_equal feed.gadget_id, link.gadget_id
  end

  def test_feed_record_rejects_gadget_id_for_other_users_feed
    other_feed = Feed.find(2)
    VisitedLink.record!(@user, 'https://example.com/feed-item', title: 'Headline', source: 'feed',
                      gadget_id: other_feed.gadget_id)

    link = VisitedLink.find_by!(user_id: @user.id, url: 'https://example.com/feed-item')
    assert_nil link.gadget_id
  end

  def test_feed_record_rejects_mismatched_gadget_id_prefix
    feed = Feed.find(1)
    VisitedLink.record!(@user, 'https://example.com/feed-item', title: 'Headline', source: 'feed',
                      gadget_id: "x_account_#{feed.id}")

    link = VisitedLink.find_by!(user_id: @user.id, url: 'https://example.com/feed-item')
    assert_nil link.gadget_id
  end

  def test_feed_record_empty_gadget_id_preserves_existing_gadget_id
    feed = Feed.find(1)
    VisitedLink.record!(@user, 'https://example.com/feed-item', title: 'Headline', source: 'feed',
                      gadget_id: feed.gadget_id)

    assert_no_difference -> { VisitedLink.count } do
      VisitedLink.record!(@user, 'https://example.com/feed-item', title: 'Updated', source: 'feed',
                          gadget_id: '   ')
    end

    link = VisitedLink.find_by!(user_id: @user.id, url: 'https://example.com/feed-item')
    assert_equal feed.gadget_id, link.gadget_id
    assert_equal 'Updated', link.title
  end

  def test_feed_record_updates_gadget_id_on_reclick_from_different_feed
    feed_one = Feed.find(1)
    feed_two = Feed.create!(user_id: @user.id, title: 'Second Feed', feed_url: 'https://example.com/rss.xml')

    VisitedLink.record!(@user, 'https://example.com/shared', title: 'Shared', source: 'feed',
                      gadget_id: feed_one.gadget_id)

    assert_no_difference -> { VisitedLink.count } do
      VisitedLink.record!(@user, 'https://example.com/shared', title: 'Shared', source: 'feed',
                          gadget_id: feed_two.gadget_id)
    end

    link = VisitedLink.find_by!(user_id: @user.id, url: 'https://example.com/shared')
    assert_equal feed_two.gadget_id, link.gadget_id
  end

  def test_gadget_titles_for_resolves_feed_x_and_mastodon
    feed = Feed.find(1)
    x_account = XAccount.create!(
      user: @user, x_user_id: '90199', username: 'gadgethist', display_name: 'Gadget Hist User',
      selected: true, deleted: false, protected: false
    )
    mastodon = MastodonAccount.find(1)

    titles = VisitedLink.gadget_titles_for(@user, [feed.gadget_id, x_account.gadget_id, mastodon.gadget_id])

    assert_equal feed.title, titles[feed.gadget_id]
    assert_equal x_account.title, titles[x_account.gadget_id]
    assert_equal mastodon.title, titles[mastodon.gadget_id]
  end

  def test_gadget_titles_for_omits_deleted_gadgets
    feed = Feed.find(1)
    titles = VisitedLink.gadget_titles_for(@user, [feed.gadget_id, 'feed_999999'])

    assert_equal({ feed.gadget_id => feed.title }, titles)
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

  # backfill_history_sources!

  def test_backfill_sets_x_source_from_canonical_status_url
    VisitedLink.record!(@user, 'https://x.com/i/status/123')

    VisitedLink.backfill_history_sources!

    link = VisitedLink.find_by!(user_id: @user.id, url: 'https://x.com/i/status/123')
    assert_equal 'x', link.source
    assert_nil link.title
  end

  def test_backfill_sets_mastodon_source_from_status_url
    VisitedLink.record!(@user, 'https://mastodon.example/@user/1')

    VisitedLink.backfill_history_sources!

    link = VisitedLink.find_by!(user_id: @user.id, url: 'https://mastodon.example/@user/1')
    assert_equal 'mastodon', link.source
    assert_nil link.title
  end

  def test_backfill_leaves_generic_url_only_rows
    VisitedLink.record!(@user, 'https://example.com/article')

    VisitedLink.backfill_history_sources!

    link = VisitedLink.find_by!(user_id: @user.id, url: 'https://example.com/article')
    assert_nil link.source
  end

  def test_backfill_does_not_match_x_user_status_url
    VisitedLink.record!(@user, 'https://x.com/user/status/1')

    VisitedLink.backfill_history_sources!

    link = VisitedLink.find_by!(user_id: @user.id, url: 'https://x.com/user/status/1')
    assert_nil link.source
  end

  def test_backfill_does_not_overwrite_existing_source
    VisitedLink.record!(@user, 'https://x.com/i/status/123', title: 'Feed Headline', source: 'feed')

    VisitedLink.backfill_history_sources!

    link = VisitedLink.find_by!(user_id: @user.id, url: 'https://x.com/i/status/123')
    assert_equal 'feed', link.source
    assert_equal 'Feed Headline', link.title
  end

  def test_backfill_is_idempotent
    VisitedLink.record!(@user, 'https://x.com/i/status/123')
    VisitedLink.backfill_history_sources!

    assert_no_difference -> { VisitedLink.where(source: 'x').count } do
      VisitedLink.backfill_history_sources!
    end
  end

  def test_backfill_includes_rows_in_feed_history_for
    VisitedLink.record!(@user, 'https://x.com/i/status/123')
    VisitedLink.record!(@user, 'https://mastodon.example/@user/1')
    VisitedLink.record!(@user, 'https://example.com/url-only')

    VisitedLink.backfill_history_sources!

    urls = VisitedLink.feed_history_for(@user).map(&:url)
    assert_includes urls, 'https://x.com/i/status/123'
    assert_includes urls, 'https://mastodon.example/@user/1'
    assert_not_includes urls, 'https://example.com/url-only'
  end

  def test_backfill_does_not_change_visited_at_or_updated_at
    VisitedLink.record!(@user, 'https://x.com/i/status/123')
    link = VisitedLink.find_by!(user_id: @user.id, url: 'https://x.com/i/status/123')
    visited_at = link.visited_at
    updated_at = link.updated_at

    VisitedLink.backfill_history_sources!

    link.reload
    assert_equal visited_at, link.visited_at
    assert_equal updated_at, link.updated_at
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
