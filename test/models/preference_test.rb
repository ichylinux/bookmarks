require 'test_helper'

class PreferenceTest < ActiveSupport::TestCase

  def test_デフォルトのユーザ設定
    p = Preference.default_preference(user)

    assert_equal Todo::PRIORITY_NORMAL, p.default_priority
    assert_equal true, p.use_todo?
    assert_equal true, p.use_calendar?
    assert_nil p.font_size
  end

  def test_文字サイズは選択肢のみ有効
    p = Preference.default_preference(user)

    Preference::FONT_SIZES.each do |font_size|
      p.font_size = font_size
      assert p.valid?, "#{font_size} should be valid"
    end

    p.font_size = nil
    assert p.valid?, 'nil should fall back at render time'

    p.font_size = 'extra-large'
    assert_not p.valid?
  end

  def test_不正値はmediumに正規化される
    assert_equal Preference::FONT_SIZE_MEDIUM, Preference.normalize_font_size(nil)
    assert_equal Preference::FONT_SIZE_MEDIUM, Preference.normalize_font_size('unknown')
    assert_equal Preference::FONT_SIZE_SMALL, Preference.normalize_font_size(Preference::FONT_SIZE_SMALL)
  end

  def test_既存ユーザーのfont_size_nil_mediumをsmallへ移行する
    legacy_nil = user.preference
    legacy_nil.update_columns(font_size: nil, font_size_notice_pending: false)

    legacy_medium = User.second.preference
    legacy_medium.update_columns(font_size: Preference::FONT_SIZE_MEDIUM, font_size_notice_pending: false)

    keep_large = User.third.preference
    keep_large.update_columns(font_size: Preference::FONT_SIZE_LARGE, font_size_notice_pending: false)

    migrated_count = Preference.migrate_legacy_font_sizes!
    assert_equal 2, migrated_count

    assert_equal Preference::FONT_SIZE_SMALL, legacy_nil.reload.font_size
    assert legacy_nil.font_size_notice_pending?
    assert_equal Preference::FONT_SIZE_SMALL, legacy_medium.reload.font_size
    assert legacy_medium.font_size_notice_pending?
    assert_equal Preference::FONT_SIZE_LARGE, keep_large.reload.font_size
    assert_not keep_large.font_size_notice_pending?

    assert_equal 0, Preference.migrate_legacy_font_sizes!
  end

  def test_portal_column_countsは3と4のみ有効
    p = Preference.default_preference(user)

    assert_equal [3, 4], Preference::PORTAL_COLUMN_COUNTS

    p.portal_column_count = 3
    assert p.valid?, '3 should be valid'

    p.portal_column_count = 4
    assert p.valid?, '4 should be valid'

    p.portal_column_count = 2
    assert_not p.valid?, '2 should be invalid'
    assert p.errors[:portal_column_count].any?, 'should have error on portal_column_count'

    p.portal_column_count = 5
    assert_not p.valid?, '5 should be invalid'

    p.portal_column_count = nil
    assert_not p.valid?, 'nil should be invalid (NOT NULL column)'
  end

  def test_デフォルトのポータル列数は3
    p = user.preference
    assert_equal 3, p.portal_column_count
  end

  def test_show_iconsのデフォルトはtrue
    p = Preference.default_preference(user)
    assert_equal true, p.show_icons
  end

  def test_show_iconsにnilは無効
    p = Preference.default_preference(user)
    p.show_icons = nil
    assert_not p.valid?, 'nil should be invalid'
    assert_includes p.errors[:show_icons], 'は一覧にありません'
  end

  def test_equal_portal_column_widthsは列数に応じた均等分割を返す
    assert_equal [34, 33, 33], Preference.equal_portal_column_widths(3)
    assert_equal [25, 25, 25, 25], Preference.equal_portal_column_widths(4)
  end

  def test_effective_portal_column_widthsは未設定時に均等分割を返す
    p = user.preference
    p.update_column(:portal_column_widths, nil)
    assert_equal [34, 33, 33], p.effective_portal_column_widths
  end

  def test_portal_column_widthsは合計100で列数と一致する必要がある
    p = user.preference
    p.assign_attributes(portal_column_count: 3, portal_column_widths: nil)
    p.portal_column_widths = [50, 30, 20]
    assert p.valid?

    p.portal_column_widths = [50, 30, 10]
    assert_not p.valid?
    assert p.errors[:portal_column_widths].any?

    p.update!(portal_column_count: 4, portal_column_widths: [25, 25, 25, 25])

    p.portal_column_widths = [50, 30, 15, 4]
    assert_equal 99, p.portal_column_widths.sum
    assert_not p.valid?
  end

  def test_列数と幅配列の長さが不一致のとき均等分割に正規化される
    p = user.preference
    p.assign_attributes(portal_column_count: 4, portal_column_widths: [50, 30, 20])
    assert p.valid?
    assert_equal [25, 25, 25, 25], p.portal_column_widths
  end

  def test_localeはsupported_localesのみ有効
    p = Preference.default_preference(user)

    Preference::SUPPORTED_LOCALES.each do |locale|
      p.locale = locale
      assert p.valid?, "#{locale} should be valid"
    end

    p.locale = nil
    assert p.valid?, 'nil locale should be valid (未指定を許可)'

    p.locale = 'fr'
    assert_not p.valid?, "'fr' should be invalid"

    p.locale = 'zh'
    assert_not p.valid?, "'zh' should be invalid"
  end

end
