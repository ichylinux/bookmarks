require 'test_helper'

class CalendarGadgetTest < ActiveSupport::TestCase
  def test_day_of_week_follows_active_locale
    gadget = CalendarGadget.new(user)

    I18n.with_locale(:ja) do
      assert_equal '日', gadget.day_of_week(0)
      assert_equal '月', gadget.day_of_week(1)
    end

    I18n.with_locale(:en) do
      assert_equal 'Sun', gadget.day_of_week(0)
      assert_equal 'Mon', gadget.day_of_week(1)
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

  def test_holiday_names_are_only_shown_in_japanese_locale
    gadget = CalendarGadget.new(user)
    gadget.display_date = Date.new(2026, 1, 1)
    new_years_day = Date.new(2026, 1, 1)

    I18n.with_locale(:ja) do
      assert gadget.holiday?(new_years_day)
      assert_equal '元日', gadget.holiday(new_years_day)
    end

    I18n.with_locale(:en) do
      assert_not gadget.holiday?(new_years_day)
      assert_nil gadget.holiday(new_years_day)
    end
  end
end
