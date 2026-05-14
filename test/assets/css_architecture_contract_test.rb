require 'test_helper'

# ARCH-01 + ARCH-02: Non-theme SCSS files must contain no theme-specific selectors.
# ARCH-03: Un-prefixed base styles must remain in non-theme source files.
#
# These are regression-guard tests. A violation means someone accidentally
# wrote theme-scoped CSS in a file that is supposed to be theme-neutral.
class CssArchitectureContractTest < ActiveSupport::TestCase
  NON_THEME_FILES = %w[
    bookmarks
    calendars
    common
    devise
    feeds
    landing
    preferences
    todos
    welcome
  ].freeze

  THEME_SELECTOR_PATTERN = /\.(modern|classic|simple)\b/

  def setup
    @non_theme_sources = NON_THEME_FILES.index_with do |name|
      Rails.root.join("app/assets/stylesheets/#{name}.css.scss").read
    end
  end

  # ARCH-01 + ARCH-02
  # Each of the 9 non-theme SCSS files must have zero occurrences of
  # .modern, .classic, or .simple selectors.
  test 'non-theme scss files contain no theme-specific class selectors' do
    violations = []

    @non_theme_sources.each do |filename, content|
      content.each_line.with_index(1) do |line, lineno|
        # Skip SCSS comments
        stripped = line.sub(%r{//.*$}, '').sub(/\/\*.*?\*\//, '')
        next unless THEME_SELECTOR_PATTERN.match?(stripped)

        violations << "#{filename}.css.scss:#{lineno}: #{line.rstrip}"
      end
    end

    assert_empty violations,
      "Theme-specific selectors found in non-theme SCSS files (regression). " \
      "Move these to app/assets/stylesheets/themes/:\n" +
      violations.join("\n")
  end

  # ARCH-01 + ARCH-02: Each file is individually clean (one assertion per file
  # so a failure message names the exact offending file).
  NON_THEME_FILES.each do |name|
    test "#{name}.css.scss contains no .modern .classic or .simple selectors" do
      content = Rails.root.join("app/assets/stylesheets/#{name}.css.scss").read
      lines_with_violations = content.each_line.with_index(1).filter_map do |line, lineno|
        stripped = line.sub(%r{//.*$}, '').sub(/\/\*.*?\*\//, '')
        "line #{lineno}: #{line.rstrip}" if THEME_SELECTOR_PATTERN.match?(stripped)
      end

      assert_empty lines_with_violations,
        "#{name}.css.scss must not contain theme selectors (.modern/.classic/.simple). " \
        "Violations:\n" + lines_with_violations.join("\n")
    end
  end

  # ARCH-03
  # The un-prefixed base rule for .preferences-form input[type="submit"] must
  # remain in preferences.css.scss. This rule provides the layout foundation
  # that all themes build upon; if it disappears, theme-specific overrides
  # will lose their base sizing/layout.
  test 'preferences.css.scss retains un-prefixed base rule for form submit button' do
    content = @non_theme_sources['preferences']
    assert_match(
      /\.preferences-form\s+input\[type="submit"\]/,
      content,
      '.preferences-form input[type="submit"] base rule must exist in ' \
      'preferences.css.scss. It was removed — restore it or ARCH-03 is broken.'
    )
  end
end
