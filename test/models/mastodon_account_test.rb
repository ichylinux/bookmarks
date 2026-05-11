require 'test_helper'

class MastodonAccountTest < ActiveSupport::TestCase
  def test_他人のアカウントは参照できない
    user = User.find(2)
    account = mastodon_accounts(:one)
    assert account.user_id != user.id
    assert_not account.readable_by?(user)
    assert_not account.updatable_by?(user)
    assert_not account.deletable_by?(user)
  end

  def test_自分のアカウントは参照できる
    user = User.find(1)
    account = mastodon_accounts(:one)
    assert account.readable_by?(user)
    assert account.updatable_by?(user)
    assert account.deletable_by?(user)
  end

  def test_parse_at_style_url
    account = MastodonAccount.new(user_id: 1, profile_url: 'https://ruby.social/@FastRuby')
    assert account.valid?, account.errors.full_messages.inspect
    assert_equal 'ruby.social', account.instance
    assert_equal 'FastRuby', account.username
  end

  def test_parse_users_style_url
    account = MastodonAccount.new(user_id: 1, profile_url: 'https://ruby.social/users/FastRuby')
    assert account.valid?, account.errors.full_messages.inspect
    assert_equal 'ruby.social', account.instance
    assert_equal 'FastRuby', account.username
  end

  def test_parse_url_without_scheme
    account = MastodonAccount.new(user_id: 1, profile_url: 'ruby.social/@FastRuby')
    assert account.valid?, account.errors.full_messages.inspect
    assert_equal 'ruby.social', account.instance
    assert_equal 'FastRuby', account.username
  end

  def test_rejects_unparseable_profile_url
    account = MastodonAccount.new(user_id: 1, profile_url: 'not_a_url')
    assert_not account.valid?
    assert account.errors[:instance].any? || account.errors[:username].any?
  end

  def test_rejects_profile_url_without_username_segment
    account = MastodonAccount.new(user_id: 1, profile_url: 'https://ruby.social/')
    assert_not account.valid?
  end

  def test_destroy_logically_soft_deletes
    account = mastodon_accounts(:one)
    account.destroy_logically!
    reloaded = MastodonAccount.find(account.id)
    assert reloaded.deleted
  end

  def test_not_deleted_scope_excludes_deleted
    account = mastodon_accounts(:one)
    account.destroy_logically!
    assert_not_includes MastodonAccount.not_deleted, account
  end

  def test_gadget_id_and_title
    account = mastodon_accounts(:one)
    assert_equal 'mastodon_account_1', account.gadget_id
    assert_equal '@FastRuby@ruby.social', account.title
  end
end
