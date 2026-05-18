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
