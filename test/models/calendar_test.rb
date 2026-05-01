require 'test_helper'

class CalendarTest < ActiveSupport::TestCase
  def test_day_of_week_follows_active_locale
    calendar = Calendar.new(user: user, title: 'Locale calendar')

    I18n.with_locale(:ja) do
      assert_equal '日', calendar.day_of_week(0)
      assert_equal '月', calendar.day_of_week(1)
    end

    I18n.with_locale(:en) do
      assert_equal 'Sun', calendar.day_of_week(0)
      assert_equal 'Mon', calendar.day_of_week(1)
    end
  end

  def test_calendar_month_format_follows_active_locale
    date = Date.new(2026, 1, 1)

    I18n.with_locale(:ja) do
      assert_equal '2026年1月', I18n.l(date, format: :calendar_month)
    end

    I18n.with_locale(:en) do
      assert_equal 'January 2026', I18n.l(date, format: :calendar_month)
    end
  end

  def test_holiday_names_remain_from_holiday_jp
    calendar = Calendar.new(user: user, title: 'Locale calendar')
    calendar.display_date = Date.new(2026, 1, 1)

    I18n.with_locale(:en) do
      assert_equal '元日', calendar.holiday(Date.new(2026, 1, 1))
    end
  end
end
