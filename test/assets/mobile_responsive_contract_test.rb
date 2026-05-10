# frozen_string_literal: true

require 'test_helper'

# MOB-01: .preferences-table block-layout stacking rules inside @media (max-width: 767px)
# MOB-02: .bookmarks-table nth-child(2) column-hide rule inside @media (max-width: 767px)
# MOB-03 (no-duplication): theme files must not repeat .preferences-table or .bookmarks-table rules
#
# These are regression-guard contract tests. A violation means either the mobile CSS was
# removed from common.css.scss, or duplicate rules crept into a theme file.
class MobileResponsiveContractTest < ActiveSupport::TestCase
  def setup
    @common  = Rails.root.join('app/assets/stylesheets/common.css.scss').read
    @modern  = Rails.root.join('app/assets/stylesheets/themes/modern.css.scss').read
    @classic = Rails.root.join('app/assets/stylesheets/themes/classic.css.scss').read
    @simple  = Rails.root.join('app/assets/stylesheets/themes/simple.css.scss').read
  end

  # -----------------------------------------------------------------------
  # MOB-01: @media (max-width: 767px) block must contain .preferences-table
  # block-layout stacking rules
  # -----------------------------------------------------------------------

  # The @media (max-width: 767px) block must exist and contain .preferences-table
  test 'common.css.scss contains preferences-table block layout inside max-width 767px media query' do
    # Capture the entire @media (max-width: 767px) block that holds .preferences-table
    # We look for the media query followed by .preferences-table containing display: block
    assert_match(
      /@media\s*\(\s*max-width\s*:\s*767px\s*\)[\s\S]*?\.preferences-table[\s\S]*?display\s*:\s*block/,
      @common,
      'common.css.scss must define .preferences-table { display: block } inside ' \
      '@media (max-width: 767px). MOB-01 block-layout stacking is missing or removed.'
    )
  end

  test 'common.css.scss preferences-table th has display block and text-align left at mobile breakpoint' do
    # The th inside .preferences-table at <=767px must have display:block AND text-align:left
    # We scan for the media block containing .preferences-table then check for th rules
    assert_match(
      /@media\s*\(\s*max-width\s*:\s*767px\s*\)[\s\S]*?\.preferences-table[\s\S]*?th[\s\S]*?text-align\s*:\s*left/,
      @common,
      'common.css.scss must set text-align: left on .preferences-table th inside ' \
      '@media (max-width: 767px). MOB-01 label left-alignment rule is missing.'
    )
  end

  test 'common.css.scss preferences-table tbody tr th td all switch to display block at mobile breakpoint' do
    # Verify display: block appears for the .preferences-table block (covers table/tbody/tr/th/td)
    # We match the media block, then count occurrences of display: block within .preferences-table scope
    media_block_match = @common.match(
      /@media\s*\(\s*max-width\s*:\s*767px\s*\)([\s\S]*)/
    )
    assert media_block_match,
      'common.css.scss must contain a @media (max-width: 767px) block. Not found.'

    media_block_content = media_block_match[1]

    # Extract just the .preferences-table rule block
    pref_table_match = media_block_content.match(
      /\.preferences-table\s*\{([\s\S]*?)\n\s*\}\s*\n\s*\.bookmarks-table/
    )
    assert pref_table_match,
      'common.css.scss @media (max-width: 767px) must contain .preferences-table block ' \
      'followed by .bookmarks-table. Block structure not found.'

    pref_table_block = pref_table_match[1]

    display_block_count = pref_table_block.scan(/display\s*:\s*block/).length
    assert display_block_count >= 4,
      "common.css.scss .preferences-table inside @media (max-width: 767px) must have " \
      "display: block on table, tbody, tr, th, td (at least 4 occurrences). " \
      "Found #{display_block_count}. MOB-01 stacking incomplete."
  end

  # -----------------------------------------------------------------------
  # MOB-02: @media (max-width: 767px) block must contain .bookmarks-table
  # nth-child(2) display:none rule
  # -----------------------------------------------------------------------

  test 'common.css.scss contains bookmarks-table nth-child(2) display none inside max-width 767px media query' do
    assert_match(
      /@media\s*\(\s*max-width\s*:\s*767px\s*\)[\s\S]*?\.bookmarks-table[\s\S]*?nth-child\(2\)[\s\S]*?display\s*:\s*none/,
      @common,
      'common.css.scss must define .bookmarks-table th:nth-child(2), td:nth-child(2) { display: none } ' \
      'inside @media (max-width: 767px). MOB-02 URL column hide rule is missing or removed.'
    )
  end

  test 'common.css.scss bookmarks-table hides both th and td second column at mobile breakpoint' do
    # Both th:nth-child(2) AND td:nth-child(2) must appear in the media block
    media_block_match = @common.match(
      /@media\s*\(\s*max-width\s*:\s*767px\s*\)([\s\S]*)/
    )
    assert media_block_match,
      'common.css.scss must contain a @media (max-width: 767px) block. Not found.'

    media_block_content = media_block_match[1]

    assert_match(
      /th:nth-child\(2\)/,
      media_block_content,
      'common.css.scss @media (max-width: 767px) must contain th:nth-child(2). ' \
      'MOB-02: th URL column selector missing.'
    )

    assert_match(
      /td:nth-child\(2\)/,
      media_block_content,
      'common.css.scss @media (max-width: 767px) must contain td:nth-child(2). ' \
      'MOB-02: td URL column selector missing.'
    )
  end

  test 'common.css.scss has exactly two max-width 767px media query blocks' do
    # Per the plan: grep -c "max-width: 767px" must return 2
    # (one existing body font-size block at line 27, one new combined block at ~line 321)
    count = @common.scan(/max-width\s*:\s*767px/).length
    assert_equal 2, count,
      "common.css.scss must contain exactly 2 occurrences of 'max-width: 767px' " \
      "(one legacy body font-size block + one new combined mobile block). " \
      "Found #{count}. Either the new block is missing, duplicated, or was split."
  end

  # -----------------------------------------------------------------------
  # MOB-03: No per-theme duplication of .preferences-table or .bookmarks-table
  # -----------------------------------------------------------------------

  test 'modern.css.scss contains no preferences-table mobile layout rules' do
    assert_no_match(
      /\.preferences-table/,
      @modern,
      'themes/modern.css.scss must NOT define any .preferences-table rules. ' \
      'All mobile layout comes from common.css.scss. Per-theme duplication breaks the single-source contract.'
    )
  end

  test 'modern.css.scss contains no bookmarks-table mobile layout rules' do
    assert_no_match(
      /\.bookmarks-table/,
      @modern,
      'themes/modern.css.scss must NOT define any .bookmarks-table rules. ' \
      'All mobile layout comes from common.css.scss. Per-theme duplication breaks the single-source contract.'
    )
  end

  test 'classic.css.scss contains no preferences-table mobile layout rules' do
    assert_no_match(
      /\.preferences-table/,
      @classic,
      'themes/classic.css.scss must NOT define any .preferences-table rules. ' \
      'All mobile layout comes from common.css.scss. Per-theme duplication breaks the single-source contract.'
    )
  end

  test 'classic.css.scss contains no bookmarks-table mobile layout rules' do
    assert_no_match(
      /\.bookmarks-table/,
      @classic,
      'themes/classic.css.scss must NOT define any .bookmarks-table rules. ' \
      'All mobile layout comes from common.css.scss. Per-theme duplication breaks the single-source contract.'
    )
  end

  test 'simple.css.scss contains no preferences-table mobile layout rules' do
    assert_no_match(
      /\.preferences-table/,
      @simple,
      'themes/simple.css.scss must NOT define any .preferences-table rules. ' \
      'All mobile layout comes from common.css.scss. Per-theme duplication breaks the single-source contract.'
    )
  end

  test 'simple.css.scss contains no bookmarks-table mobile layout rules' do
    assert_no_match(
      /\.bookmarks-table/,
      @simple,
      'themes/simple.css.scss must NOT define any .bookmarks-table rules. ' \
      'All mobile layout comes from common.css.scss. Per-theme duplication breaks the single-source contract.'
    )
  end
end
