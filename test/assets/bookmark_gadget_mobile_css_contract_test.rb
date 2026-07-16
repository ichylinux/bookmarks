require 'test_helper'

# Mobile bookmark gadget: "追加" link is hidden by default and revealed when the
# user taps the header title/icon (bookmark_gadget.js toggles
# title--gadget-actions-visible), matching the task gadget's mobile behavior.
# QUICK-MOB-BM-ADD-01
class BookmarkGadgetMobileCssContractTest < ActiveSupport::TestCase
  def setup
    @welcome = Rails.root.join('app/assets/stylesheets/welcome.css.scss').read
    @bookmark_gadget_js = Rails.root.join('app/assets/javascripts/bookmark_gadget.js').read
  end

  test 'welcome.css.scss hides bookmark-gadget-new-link on mobile by default (QUICK-MOB-BM-ADD-01)' do
    assert_match(
      /@media\s*\(\s*max-width\s*:\s*767px\s*\)[\s\S]*?\.title--gadget-with-icon\[data-gadget-icon="bookmark"\][\s\S]*?\.bookmark-gadget-new-link[\s\S]*?opacity\s*:\s*0/,
      @welcome,
      'welcome.css.scss must set opacity: 0 on .bookmark-gadget-new-link scoped under ' \
      '.title--gadget-with-icon[data-gadget-icon="bookmark"] inside @media (max-width: 767px). (QUICK-MOB-BM-ADD-01)'
    )

    assert_match(
      /@media\s*\(\s*max-width\s*:\s*767px\s*\)[\s\S]*?\.title--gadget-with-icon\[data-gadget-icon="bookmark"\][\s\S]*?\.bookmark-gadget-new-link[\s\S]*?pointer-events\s*:\s*none/,
      @welcome,
      'welcome.css.scss must set pointer-events: none on .bookmark-gadget-new-link scoped under ' \
      '.title--gadget-with-icon[data-gadget-icon="bookmark"] inside @media (max-width: 767px). (QUICK-MOB-BM-ADD-01)'
    )
  end

  test 'welcome.css.scss reveals bookmark-gadget-new-link when header has actions-visible class (QUICK-MOB-BM-ADD-01)' do
    assert_match(
      /\.title--gadget-with-icon\[data-gadget-icon="bookmark"\]\.title--gadget-actions-visible[\s\S]*?\.bookmark-gadget-new-link[\s\S]*?opacity\s*:\s*1/,
      @welcome,
      'welcome.css.scss must set opacity: 1 on .bookmark-gadget-new-link when the bookmark header ' \
      'carries .title--gadget-actions-visible. (QUICK-MOB-BM-ADD-01)'
    )

    assert_match(
      /\.title--gadget-with-icon\[data-gadget-icon="bookmark"\]\.title--gadget-actions-visible[\s\S]*?\.bookmark-gadget-new-link[\s\S]*?pointer-events\s*:\s*auto/,
      @welcome,
      'welcome.css.scss must set pointer-events: auto on .bookmark-gadget-new-link when the bookmark header ' \
      'carries .title--gadget-actions-visible. (QUICK-MOB-BM-ADD-01)'
    )
  end

  test 'bookmark_gadget.js binds header tap-to-reveal on the bookmark header (QUICK-MOB-BM-ADD-01)' do
    assert_match(
      /\.on\(\s*['"]click['"],\s*(BOOKMARK_HEADER_SELECTOR|['"]\.title--gadget-with-icon\[data-gadget-icon="bookmark"\]['"])/,
      @bookmark_gadget_js,
      'bookmark_gadget.js must delegate a click handler on the bookmark header ' \
      '(.title--gadget-with-icon[data-gadget-icon="bookmark"]) that toggles title--gadget-actions-visible. (QUICK-MOB-BM-ADD-01)'
    )

    assert_match(
      /toggleClass\(\s*['"]title--gadget-actions-visible['"]\s*\)/,
      @bookmark_gadget_js,
      'bookmark_gadget.js must toggleClass("title--gadget-actions-visible") on the bookmark header tap. (QUICK-MOB-BM-ADD-01)'
    )
  end

  test 'bookmark_gadget.js stops propagation on mousedown/touchstart for the add link (QUICK-MOB-BM-ADD-01)' do
    assert_match(
      /\.on\(\s*['"]mousedown touchstart['"],\s*['"]\.bookmark-gadget-new-link['"]/,
      @bookmark_gadget_js,
      'bookmark_gadget.js must bind mousedown touchstart on .bookmark-gadget-new-link and stopPropagation, ' \
      'so jQuery UI sortable / touch-punch cannot swallow the tap on mobile. (QUICK-MOB-BM-ADD-01)'
    )
  end
end
