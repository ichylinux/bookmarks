require 'test_helper'

class ApplicationHelperTest < ActionView::TestCase
  include ApplicationHelper

  test "changelog_entries returns entries sorted by date descending" do
    entries = changelog_entries
    dates = entries.map { |e| e[:date] }
    assert_equal dates.sort.reverse, dates,
      "Expected entries sorted by date descending, got: #{dates.inspect}"
  end

  test "changelog_entries caps result at 10" do
    assert changelog_entries.size <= 10,
      "Expected at most 10 entries, got #{changelog_entries.size}"
  end

  test "changelog_entries returns all entries when fewer than 10 exist" do
    entries = changelog_entries
    all_entries = I18n.t('landing.changelog.entries', default: [])
    expected_count = [all_entries.size, 10].min
    assert_equal expected_count, entries.size
  end

  test "each entry has required keys" do
    changelog_entries.each do |entry|
      assert entry[:date].present?,        "Missing :date in #{entry.inspect}"
      assert entry[:headline].present?,    "Missing :headline in #{entry.inspect}"
      assert entry[:tag].present?,         "Missing :tag in #{entry.inspect}"
      assert entry[:description].present?, "Missing :description in #{entry.inspect}"
    end
  end
end
