require 'test_helper'

class MastodonHandleNormalizerTest < ActiveSupport::TestCase
  def test_normalize_accepts_at_user_at_instance
    result = MastodonHandleNormalizer.normalize('@Alice@Mastodon.Social')

    assert result.success?
    assert_equal 'Alice@mastodon.social', result.handle
  end

  def test_normalize_accepts_bare_user_at_instance
    result = MastodonHandleNormalizer.normalize('alice@ruby.social')

    assert result.success?
    assert_equal 'alice@ruby.social', result.handle
  end

  def test_normalize_accepts_profile_url
    result = MastodonHandleNormalizer.normalize('https://mastodon.social/@alice')

    assert result.success?
    assert_equal 'alice@mastodon.social', result.handle
  end

  def test_normalize_strips_trailing_slash_from_url
    result = MastodonHandleNormalizer.normalize('https://mastodon.social/@alice/')

    assert result.success?
    assert_equal 'alice@mastodon.social', result.handle
  end

  def test_normalize_blank_returns_blank_error
    result = MastodonHandleNormalizer.normalize('   ')

    refute result.success?
    assert_equal :blank, result.error_key
  end

  def test_normalize_rejects_path_in_url
    result = MastodonHandleNormalizer.normalize('https://mastodon.social/@alice/posts/1')

    refute result.success?
    assert_equal :invalid, result.error_key
  end

  def test_normalize_rejects_scheme_without_separator
    result = MastodonHandleNormalizer.normalize('https://mastodon.social')

    refute result.success?
    assert_equal :invalid, result.error_key
  end

  def test_normalize_rejects_ipv4_instance
    result = MastodonHandleNormalizer.normalize('alice@192.168.1.1')

    refute result.success?
    assert_equal :invalid, result.error_key
  end

  def test_normalize_rejects_handle_without_separator
    result = MastodonHandleNormalizer.normalize('@mastodon.social')

    refute result.success?
    assert_equal :missing_separator, result.error_key
  end
end
