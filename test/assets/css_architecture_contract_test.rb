require 'test_helper'

# ARCH-01 + ARCH-02: Non-theme SCSS files must contain no theme-specific selectors.
# ARCH-03: Un-prefixed base styles must remain in non-theme source files.
# WINCHR-01: No stylesheet may gate a style on a hover/pointer media feature.
#
# These are regression-guard tests. A violation means someone accidentally
# wrote theme-scoped CSS in a file that is supposed to be theme-neutral.
#
# == WINCHR-01 (canonical rationale — other sites link here, do not restate it)
#
# Real-hardware evidence: Chrome 151 / Windows 10, maxTouchPoints 10,
# innerWidth 1289, touchscreen laptop. While the user was driving an actual
# mouse, all four hover/pointer media feature axes — the primary-only pair
# (hover / pointer) and the any-input pair (any-hover / any-pointer) —
# reported none/coarse. A device-capability gate therefore silently removes
# the affordance it guards for real mouse users on such machines.
#
# The rule: gate on viewport width (`min-width: $portal-mobile-breakpoint`),
# never on an input-device capability. Sticky :hover on touch devices is
# handled instead by higher-specificity hide rules inside the mobile block.
# Source: quick task 260831-1mg (commit 71b8c47).
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

  # WINCHR-01: any `@media` condition naming hover/pointer, in either the
  # primary-only or the any-input family.
  HOVER_POINTER_GATE_PATTERN = /\(\s*(any-)?(hover|pointer)\s*:/

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

  # WINCHR-01: applies to every stylesheet, themes included — see the canonical
  # rationale in this class's header comment.
  test 'no stylesheet gates styles on hover/pointer media features (WINCHR-01)' do
    violations = Dir[Rails.root.join('app/assets/stylesheets/**/*.scss')].sort.flat_map do |path|
      relative = Pathname.new(path).relative_path_from(Rails.root).to_s
      File.read(path).scan(/@media[^{]*/).filter_map do |condition|
        "#{relative}: @media #{condition.sub('@media', '').strip}" if HOVER_POINTER_GATE_PATTERN.match?(condition)
      end
    end

    assert_empty violations,
      'Stylesheets must not gate any style on a hover/pointer media feature ' \
      '(hover/pointer or any-hover/any-pointer). Chrome on a Windows touchscreen ' \
      'laptop reports none/coarse for all four axes while a real mouse is in use, ' \
      'so such a gate silently disables the affordance on a genuine desktop. ' \
      "Gate on viewport width instead — see WINCHR-01 in this file's header.\n" +
      violations.join("\n")
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
