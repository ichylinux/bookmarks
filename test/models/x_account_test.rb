require 'test_helper'

class XAccountTest < ActiveSupport::TestCase

  def test_display_countのデフォルト値が設定される
    user = users(:twitter_user)
    acc = XAccount.new(user: user, x_user_id: '99010', username: 'dcdefault', display_name: 'DC Default')
    acc.save!
    assert_equal 5, acc.display_count
  ensure
    acc&.delete
  end

  def test_display_countは正の整数でなければならない
    user = users(:twitter_user)
    acc = XAccount.new(user: user, x_user_id: '99011', username: 'dcvalid', display_name: 'DC Valid', display_count: -1)
    assert_not acc.valid?
    assert acc.errors[:display_count].any?
  end

  def test_display_countは整数でなければならない
    user = users(:twitter_user)
    acc = XAccount.new(user: user, x_user_id: '99012', username: 'dcint', display_name: 'DC Int', display_count: 2.5)
    assert_not acc.valid?
    assert acc.errors[:display_count].any?
  end

  def test_refresh_cache_soft_deletes_unselected_row_missing_from_payload
    user = users(:twitter_user)
    acc = XAccount.create!(
      user: user,
      x_user_id: '90001',
      username: 'orphan',
      display_name: 'Orphan',
      selected: false,
      deleted: false
    )

    XAccount.refresh_cache_from_items!(user, [])

    acc.reload
    assert acc.deleted?
    assert_equal 1, XAccount.where(user_id: user.id, x_user_id: '90001').count
  end

  def test_refresh_cache_soft_deletes_selected_row_missing_from_payload
    user = users(:twitter_user)
    acc = XAccount.create!(
      user: user,
      x_user_id: '90002',
      username: 'pinned',
      display_name: 'Pinned',
      selected: true,
      deleted: false
    )

    XAccount.refresh_cache_from_items!(user, [])

    acc.reload
    assert acc.deleted?
    assert acc.selected?
    assert_equal 1, XAccount.where(user_id: user.id, x_user_id: '90002').count
  end

  def test_refresh_cache_clears_deleted_when_account_returns_in_payload
    user = users(:twitter_user)
    acc = XAccount.create!(
      user: user,
      x_user_id: '90003',
      username: 'back',
      display_name: 'Back',
      selected: true,
      deleted: true
    )

    XAccount.refresh_cache_from_items!(
      user,
      [{ id: '90003', username: 'back', name: 'Back Again', protected: false }]
    )

    acc.reload
    assert_not acc.deleted?
    assert_equal 'Back Again', acc.display_name
  end

  def test_upsert_manual_新規レコードが作成される
    user = users(:twitter_user)
    acc = XAccount.upsert_manual!(user: user, x_user_id: '90100', username: 'manualuser', display_name: 'Manual User')
    assert_equal 1, XAccount.where(user_id: user.id, x_user_id: '90100').count
    assert acc.manually_added?
    assert_not acc.deleted?
  ensure
    XAccount.where(user_id: user.id, x_user_id: '90100').delete_all
  end

  def test_upsert_manual_ソフト削除済みを復元する
    user = users(:twitter_user)
    existing = XAccount.create!(user: user, x_user_id: '90101', username: 'ghost', display_name: 'Ghost', deleted: true, manually_added: false)
    XAccount.upsert_manual!(user: user, x_user_id: '90101', username: 'ghost', display_name: 'Ghost')
    assert_equal 1, XAccount.where(user_id: user.id, x_user_id: '90101').count
    existing.reload
    assert_not existing.deleted?
    assert existing.manually_added?
  ensure
    XAccount.where(user_id: user.id, x_user_id: '90101').delete_all
  end

  def test_refresh_guard_manually_added行は削除されない
    user = users(:twitter_user)
    acc = XAccount.create!(user: user, x_user_id: '90102', username: 'keeper', display_name: 'Keeper', manually_added: true, deleted: false)
    XAccount.refresh_cache_from_items!(user, [])
    acc.reload
    assert_not acc.deleted?
  ensure
    XAccount.where(user_id: user.id, x_user_id: '90102').delete_all
  end

  def test_refresh_guard_overlap行のmanually_addedはtrueのまま
    user = users(:twitter_user)
    acc = XAccount.create!(user: user, x_user_id: '90103', username: 'overlap', display_name: 'Overlap', manually_added: true, deleted: false)
    XAccount.refresh_cache_from_items!(user, [{ id: '90103', username: 'overlap', name: 'Overlap Refreshed', protected: false }])
    acc.reload
    assert acc.manually_added?
    assert_not acc.deleted?
    assert_equal 'Overlap Refreshed', acc.display_name
  ensure
    XAccount.where(user_id: user.id, x_user_id: '90103').delete_all
  end
end
