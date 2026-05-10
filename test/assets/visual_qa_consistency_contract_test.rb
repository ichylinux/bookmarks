# frozen_string_literal: true

require 'test_helper'

# Phase 050-01 regression-guard contract tests.
#
# Gap 1 (CSS-fix regression): Ensure the redundant `.modern .preferences-table th { text-align: right }`
# rule does NOT re-appear in themes/modern.css.scss. The rule was removed in 050-01-01 because
# common.css.scss already defines `.preferences-table th { text-align: right }` for all themes.
#
# Gap 2 (CONS-02 action links): Ensure the .actions a architecture is intact:
#   - common.css.scss defines the neutral-grey base (.actions a/#595757)
#   - modern.css.scss provides the blue-accent override (.modern .actions a + :visited)
#   - classic.css.scss does NOT override .actions a (uses common base intentionally)
#   - simple.css.scss  does NOT override .actions a (uses common base intentionally)
class VisualQaConsistencyContractTest < ActiveSupport::TestCase
  def setup
    @common  = Rails.root.join('app/assets/stylesheets/common.css.scss').read
    @modern  = Rails.root.join('app/assets/stylesheets/themes/modern.css.scss').read
    @classic = Rails.root.join('app/assets/stylesheets/themes/classic.css.scss').read
    @simple  = Rails.root.join('app/assets/stylesheets/themes/simple.css.scss').read
  end

  # -----------------------------------------------------------------------
  # Gap 1 — CSS-fix regression guard
  # -----------------------------------------------------------------------

  # PREFS-01: common.css.scss must use a child-combinator selector with specificity (0,1,3) so it
  # beats .modern table th (0,1,2) without needing a theme-scoped override in modern.css.scss.
  test 'common.css.scss defines high-specificity preferences-table th text-align right rule' do
    assert_match(
      /\.preferences-table\s*>\s*tbody\s*>\s*tr\s*>\s*th[\s\S]{0,60}text-align:\s*right/,
      @common,
      'common.css.scss must define .preferences-table > tbody > tr > th { text-align: right } ' \
      '(specificity 0,1,3) to beat .modern table th (0,1,2). Do not revert to the lower-specificity form.'
    )
  end

  # Confirm the canonical base rule remains in common.css.scss so the regression guard above is meaningful.
  test 'common.css.scss retains the canonical preferences-table th text-align right rule' do
    assert_match(
      /\.preferences-table[\s\S]{0,60}th[\s\S]{0,60}text-align:\s*right/,
      @common,
      'common.css.scss must define .preferences-table th { text-align: right } (base for all themes). ' \
      'If this is missing, restore it.'
    )
  end

  # -----------------------------------------------------------------------
  # Gap 2 — CONS-02: .actions a architecture contract
  # -----------------------------------------------------------------------

  # common.css.scss must define the neutral-grey base rule for .actions a
  test 'common.css.scss defines neutral-grey base rule for .actions a' do
    # Pattern: .actions block containing a or a:visited with neutral grey colour (#595757)
    assert_match(
      /\.actions[\s\S]{0,200}#595757/,
      @common,
      'common.css.scss must define .actions a with neutral grey color (#595757). ' \
      'This is the base rule applied to all themes.'
    )
  end

  # modern.css.scss must provide the blue-accent override for .actions a
  test 'modern.css.scss provides blue-accent override for .modern .actions a' do
    assert_match(
      /\.modern\s+\.actions\s+a\b/,
      @modern,
      'themes/modern.css.scss must define .modern .actions a (blue-accent override). ' \
      'CONS-02 requires modern theme to style action links in blue (#3b82f6 accent).'
    )
  end

  # modern.css.scss must also cover :visited so visited links share the blue style
  test 'modern.css.scss provides blue-accent override for .modern .actions a:visited' do
    assert_match(
      /\.modern\s+\.actions\s+a:visited\b/,
      @modern,
      'themes/modern.css.scss must define .modern .actions a:visited override. ' \
      'Without it, visited action links revert to the browser default purple rather than the blue accent.'
    )
  end

  # classic.css.scss must NOT define any .actions a rule (uses common neutral grey intentionally)
  test 'classic.css.scss does not override .actions a (neutral grey from common is correct)' do
    # Look for any selector that is specifically .classic .actions a
    assert_no_match(
      /\.classic\s+\.actions\s+a\b/,
      @classic,
      'themes/classic.css.scss must NOT override .actions a. ' \
      'Classic intentionally inherits the neutral grey from common.css.scss.'
    )
  end

  # simple.css.scss must NOT define any .actions a rule (uses common neutral grey intentionally)
  test 'simple.css.scss does not override .actions a (neutral grey from common is correct)' do
    assert_no_match(
      /\.simple\s+\.actions\s+a\b/,
      @simple,
      'themes/simple.css.scss must NOT override .actions a. ' \
      'Simple intentionally inherits the neutral grey from common.css.scss.'
    )
  end
end
