# frozen_string_literal: true

require 'test_helper'

class UserPurgeTest < ActiveSupport::TestCase
  ASSOCIATED_TABLES = %i[
    bookmarks feeds mastodon_accounts notes portal_layouts portals
    preferences todos visited_links x_accounts x_api_calls
  ].freeze

  def purge_test_user(deleted_at:)
    User.create!(
      email: "purge-test-#{SecureRandom.hex(4)}@example.com",
      password: Devise.friendly_token[0, 20]
    ).tap do |u|
      u.update_columns(deleted: true, deleted_at: deleted_at)
    end
  end

  def seed_associated_records!(user)
    Bookmark.create!(user_id: user.id, title: 't', url: 'https://example.com')
    Feed.create!(user_id: user.id, title: 'f', feed_url: 'https://example.com/feed')
    MastodonAccount.create!(
      user_id: user.id, instance: 'example.social', username: 'u', profile_url: 'https://example.social/@u'
    )
    Note.create!(user_id: user.id, body: 'note')
    PortalLayout.create!(user_id: user.id, gadget_id: 'bookmarks', column_no: 0, display_order: 0)
    Portal.create!(user_id: user.id, name: 'Home')
    Preference.create!(user_id: user.id)
    Todo.create!(user_id: user.id, title: 'todo', priority: 1)
    VisitedLink.create!(user_id: user.id, url: 'https://visited.example', visited_at: Time.current)
    XAccount.create!(
      user_id: user.id, x_user_id: "x-#{SecureRandom.hex(4)}", username: 'handle', display_name: 'Handle'
    )
    XApiCall.create!(
      user_id: user.id, endpoint: '/2/users', called_at: Time.current, success: true
    )
  end

  def associated_counts(user_id)
    {
      bookmarks: Bookmark.where(user_id: user_id).count,
      feeds: Feed.where(user_id: user_id).count,
      mastodon_accounts: MastodonAccount.where(user_id: user_id).count,
      notes: Note.where(user_id: user_id).count,
      portal_layouts: PortalLayout.where(user_id: user_id).count,
      portals: Portal.where(user_id: user_id).count,
      preferences: Preference.where(user_id: user_id).count,
      todos: Todo.where(user_id: user_id).count,
      visited_links: VisitedLink.where(user_id: user_id).count,
      x_accounts: XAccount.where(user_id: user_id).count,
      x_api_calls: XApiCall.where(user_id: user_id).count
    }
  end

  def test_purgeable_false_for_active_user
    u = users(:two)
    assert_not u.purgeable?
  end

  def test_purgeable_false_when_deleted_at_nil
    u = purge_test_user(deleted_at: nil)
    assert_not u.purgeable?
  end

  def test_purgeable_false_when_deleted_at_89_days_ago
    u = purge_test_user(deleted_at: 89.days.ago)
    assert_not u.purgeable?
  end

  def test_purgeable_true_when_deleted_at_exactly_90_days_ago
    u = purge_test_user(deleted_at: User::PURGE_AFTER_DAYS.days.ago)
    assert_predicate u, :purgeable?
  end

  def test_purgeable_true_when_deleted_at_91_days_ago
    u = purge_test_user(deleted_at: 91.days.ago)
    assert_predicate u, :purgeable?
  end

  def test_purgeable_scope_includes_eligible_and_excludes_ineligible
    eligible = purge_test_user(deleted_at: 91.days.ago)
    ineligible = purge_test_user(deleted_at: 1.day.ago)

    ids = User.purgeable.pluck(:id)
    assert_includes ids, eligible.id
    assert_not_includes ids, ineligible.id
  end

  def test_purge_raises_on_non_purgeable_user
    u = users(:two)
    seed_associated_records!(u)
    counts_before = associated_counts(u.id)

    assert_raises(User::NotPurgeableError) { u.purge! }

    assert User.exists?(u.id)
    assert_equal counts_before, associated_counts(u.id)
  end

  def test_purge_deletes_all_associated_tables_and_user
    u = purge_test_user(deleted_at: 91.days.ago)
    seed_associated_records!(u)
    user_id = u.id

    ASSOCIATED_TABLES.each do |table|
      assert_operator associated_counts(user_id)[table], :>, 0, "expected #{table} rows before purge"
    end

    u.purge!

    assert_not User.exists?(user_id)
    ASSOCIATED_TABLES.each do |table|
      assert_equal 0, associated_counts(user_id)[table], "expected no #{table} rows after purge"
    end
  end
end
