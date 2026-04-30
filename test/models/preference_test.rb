require 'test_helper'

class PreferenceTest < ActiveSupport::TestCase

  def test_デフォルトのユーザ設定
    p = Preference.default_preference(user)

    assert_equal Todo::PRIORITY_NORMAL, p.default_priority
    assert_equal true, p.use_todo?
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

end
