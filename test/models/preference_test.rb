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
