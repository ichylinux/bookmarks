require 'test_helper'

class PreferenceTest < ActiveSupport::TestCase

  def test_デフォルトのユーザ設定
    p = Preference.default_preference(user)

    assert_equal Todo::PRIORITY_NORMAL, p.default_priority
    assert_equal true, p.use_todo?
  end

end
