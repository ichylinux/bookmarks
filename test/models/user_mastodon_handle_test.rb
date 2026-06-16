require 'test_helper'

class UserMastodonHandleTest < ActiveSupport::TestCase
  def test_normalize_mastodon_handle_on_save
    user = users(:one)
    user.mastodon_handle = '@alice@Mastodon.Social'

    assert user.save
    assert_equal 'alice@mastodon.social', user.mastodon_handle
  end

  def test_blank_mastodon_handle_clears_field
    user = users(:one)
    user.update!(mastodon_handle: 'alice@mastodon.social')

    user.mastodon_handle = '   '
    assert user.save
    assert_nil user.mastodon_handle
  end

  def test_invalid_mastodon_handle_adds_error
    user = users(:one)
    user.mastodon_handle = 'not-a-handle'

    refute user.save
    assert user.errors[:mastodon_handle].present?
  end

  def test_mastodon_handle_uniqueness
    users(:one).update!(mastodon_handle: 'alice@mastodon.social')
    user = users(:two)
    user.mastodon_handle = 'alice@mastodon.social'

    refute user.valid?
    assert_equal :taken, user.errors.details[:mastodon_handle].first[:error]
  end

  def test_multiple_users_may_have_blank_mastodon_handle
    users(:one).update!(mastodon_handle: nil)
    user = users(:two)
    user.mastodon_handle = nil

    assert user.save
  end
end
