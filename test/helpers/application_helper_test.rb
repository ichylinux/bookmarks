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

  # visited_link_class unit tests (VIS-02)

  test "visited_link_class returns link--visited when url is in the set" do
    visited_set = Set["https://example.com/page"]
    assert_equal "link--visited", visited_link_class(visited_set, "https://example.com/page")
  end

  test "visited_link_class returns empty string when url is not in the set" do
    visited_set = Set["https://other.com"]
    assert_equal "", visited_link_class(visited_set, "https://example.com/page")
  end

  test "visited_link_class normalizes url before lookup (strips fragment)" do
    visited_set = Set["https://example.com/page"]
    assert_equal "link--visited", visited_link_class(visited_set, "https://example.com/page#section")
  end

  test "visited_link_class returns empty string for empty set" do
    assert_equal "", visited_link_class(Set.new, "https://example.com/page")
  end

  test "visited_link_class returns empty string when visited_set is nil (GAD-04 nil-guard)" do
    assert_equal "", visited_link_class(nil, "https://example.com/page")
  end

  # CSS contract test (VIS-01 + VIS-02 success criterion 3)

  test "common.css.scss defines .link--visited selector" do
    css_path = Rails.root.join("app/assets/stylesheets/common.css.scss")
    assert File.read(css_path).include?(".link--visited"),
      "Expected common.css.scss to contain '.link--visited' but it did not"
  end

  test "common.css.scss excludes bookmark gadget from visited-link dimming" do
    css_path = Rails.root.join("app/assets/stylesheets/common.css.scss")
    css = File.read(css_path)
    assert_includes css, "#bookmark_gadget"
    assert_includes css, "opacity: 1"
  end
end
