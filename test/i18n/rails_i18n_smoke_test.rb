require 'test_helper'

class RailsI18nSmokeTest < ActiveSupport::TestCase
  def test_railsI18nのjaメッセージが解決される
    ja_blank = I18n.with_locale(:ja) { I18n.t('errors.messages.blank') }
    assert_equal 'を入力してください', ja_blank
  end

  def test_railsI18nのenメッセージが解決される
    en_blank = I18n.with_locale(:en) { I18n.t('errors.messages.blank') }
    assert_equal "can't be blank", en_blank
  end
end
