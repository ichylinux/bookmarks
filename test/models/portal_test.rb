require 'test_helper'

class PortalTest < ActiveSupport::TestCase

  def portal
    @portal ||= portals(:p_1)
  end

  def test_portal_column_countはpreference設定を委譲する
    user.preference.update_columns(portal_column_count: 3)
    assert_equal 3, portal.portal_column_count

    user.preference.update_columns(portal_column_count: 4)
    portal.instance_variable_set(:@portal_columns, nil)
    assert_equal 4, portal.portal_column_count
  end

  def test_portal_columnsは設定カラム数の配列を返す
    user.preference.update_columns(portal_column_count: 3)
    columns = portal.portal_columns
    assert_equal 3, columns.size
    columns.each { |c| assert_kind_of Array, c }

    user.preference.update_columns(portal_column_count: 4)
    portal.instance_variable_set(:@portal_columns, nil)
    columns = portal.portal_columns
    assert_equal 4, columns.size
    columns.each { |c| assert_kind_of Array, c }
  end

  def test_column_no超過のPortalLayoutはスキップされる
    user.preference.update_columns(portal_column_count: 3)
    # Create a PortalLayout record at column_no=3 (index 3 is out of range for 3-column layout)
    pl = PortalLayout.create!(
      user_id: user.id,
      column_no: 3,
      display_order: 0,
      gadget_id: 'bookmark'
    )
    columns = portal.portal_columns
    assert_equal 3, columns.size
    # No nil entries and no IndexError
    columns.each { |c| assert_kind_of Array, c }
    pl.destroy
  end

end
