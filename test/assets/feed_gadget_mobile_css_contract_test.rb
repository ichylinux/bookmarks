require 'test_helper'

# Mobile feed gadget: "設定" link is hidden by default and revealed when the
# user taps the header title/icon (feed_gadget.js toggles
# title--gadget-actions-visible), matching the bookmark/task gadget pattern.
class FeedGadgetMobileCssContractTest < ActiveSupport::TestCase
  def setup
    @welcome = Rails.root.join('app/assets/stylesheets/welcome.css.scss').read
    @feed_gadget_js = Rails.root.join('app/assets/javascripts/feed_gadget.js').read
  end

  test 'welcome.css.scss hides feed-gadget-settings-link on mobile by default' do
    assert_match(
      /@media\s*\(\s*max-width\s*:\s*767px\s*\)[\s\S]*?\.title--gadget-with-icon\[data-gadget-icon="feed"\][\s\S]*?\.feed-gadget-settings-link[\s\S]*?opacity\s*:\s*0/,
      @welcome,
      'welcome.css.scss must set opacity: 0 on .feed-gadget-settings-link scoped under ' \
      '.title--gadget-with-icon[data-gadget-icon="feed"] inside @media (max-width: 767px).'
    )

    assert_match(
      /@media\s*\(\s*max-width\s*:\s*767px\s*\)[\s\S]*?\.title--gadget-with-icon\[data-gadget-icon="feed"\][\s\S]*?\.feed-gadget-settings-link[\s\S]*?pointer-events\s*:\s*none/,
      @welcome,
      'welcome.css.scss must set pointer-events: none on .feed-gadget-settings-link scoped under ' \
      '.title--gadget-with-icon[data-gadget-icon="feed"] inside @media (max-width: 767px).'
    )
  end

  test 'welcome.css.scss reveals feed-gadget-settings-link when header has actions-visible class' do
    assert_match(
      /\.title--gadget-with-icon\[data-gadget-icon="feed"\]\.title--gadget-actions-visible[\s\S]*?\.feed-gadget-settings-link[\s\S]*?opacity\s*:\s*1/,
      @welcome,
      'welcome.css.scss must set opacity: 1 on .feed-gadget-settings-link when the feed header ' \
      'carries .title--gadget-actions-visible.'
    )

    assert_match(
      /\.title--gadget-with-icon\[data-gadget-icon="feed"\]\.title--gadget-actions-visible[\s\S]*?\.feed-gadget-settings-link[\s\S]*?pointer-events\s*:\s*auto/,
      @welcome,
      'welcome.css.scss must set pointer-events: auto on .feed-gadget-settings-link when the feed header ' \
      'carries .title--gadget-actions-visible.'
    )
  end

  test 'feed_gadget.js binds header tap-to-reveal on the feed header' do
    assert_match(
      /\.on\(\s*['"]click['"],\s*(FEED_HEADER_SELECTOR|['"]\.title--gadget-with-icon\[data-gadget-icon="feed"\]['"])/,
      @feed_gadget_js,
      'feed_gadget.js must delegate a click handler on the feed header ' \
      '(.title--gadget-with-icon[data-gadget-icon="feed"]) that toggles title--gadget-actions-visible.'
    )

    assert_match(
      /toggleClass\(\s*['"]title--gadget-actions-visible['"]\s*\)/,
      @feed_gadget_js,
      'feed_gadget.js must toggleClass("title--gadget-actions-visible") on the feed header tap.'
    )
  end

  test 'feed_gadget.js stops propagation on mousedown/touchstart for the settings link' do
    assert_match(
      /\.on\(\s*['"]mousedown touchstart['"],\s*['"]\.feed-gadget-settings-link['"]/,
      @feed_gadget_js,
      'feed_gadget.js must bind mousedown touchstart on .feed-gadget-settings-link and stopPropagation, ' \
      'so jQuery UI sortable / touch-punch cannot swallow the tap on mobile.'
    )
  end

  test 'feed_gadget.js stops immediate propagation on the feed header via .gadgets' do
    assert_match(
      /\.gadgets[\s\S]*?stopImmediatePropagation\(\)/,
      @feed_gadget_js,
      'feed_gadget.js must bind on .gadgets and stopImmediatePropagation on the feed header ' \
      'so touch-punch cannot suppress the reveal click on mobile.'
    )
  end

  test 'feed_gadget.js prevents default navigation on first mobile header tap' do
    assert_match(
      /MOBILE_MQ\.matches[\s\S]*?preventDefault\(\)/,
      @feed_gadget_js,
      'feed_gadget.js must call preventDefault on the mobile feed header tap so the site-name ' \
      'link does not navigate before revealing the settings link.'
    )
  end
end
