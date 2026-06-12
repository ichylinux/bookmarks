require 'test_helper'

class MastodonInstanceNormalizerTest < ActiveSupport::TestCase
  def test_normalize_strips_scheme_at_and_trailing_slash
    result = MastodonInstanceNormalizer.normalize('https://@Mastodon.Social/')

    assert result.success?
    assert_equal 'mastodon.social', result.hostname
  end

  def test_normalize_accepts_http_scheme
    result = MastodonInstanceNormalizer.normalize('http://ruby.social')

    assert result.success?
    assert_equal 'ruby.social', result.hostname
  end

  def test_normalize_rejects_blank
    result = MastodonInstanceNormalizer.normalize('   ')

    refute result.success?
    assert_equal :blank, result.error_key
  end

  def test_normalize_rejects_path_segments
    result = MastodonInstanceNormalizer.normalize('mastodon.social/foo')

    refute result.success?
    assert_equal :invalid, result.error_key
  end

  def test_normalize_rejects_single_label_hostname
    result = MastodonInstanceNormalizer.normalize('localhost')

    refute result.success?
    assert_equal :invalid, result.error_key
  end

  def test_normalize_rejects_ipv4_literal
    result = MastodonInstanceNormalizer.normalize('192.168.1.1')

    refute result.success?
    assert_equal :invalid, result.error_key
  end

  def test_normalize_rejects_ipv6_literal
    result = MastodonInstanceNormalizer.normalize('::1')

    refute result.success?
    assert_equal :invalid, result.error_key
  end

  def test_normalize_rejects_malformed_scheme
    result = MastodonInstanceNormalizer.normalize('ftp://mastodon.social')

    refute result.success?
    assert_equal :invalid, result.error_key
  end
end
