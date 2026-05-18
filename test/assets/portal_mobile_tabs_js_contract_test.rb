require 'test_helper'

class PortalMobileTabsJsContractTest < ActiveSupport::TestCase
  def setup
    @source = Rails.root.join('app/assets/javascripts/portal_mobile_tabs.js').read
    @welcome_stylesheet = Rails.root.join('app/assets/stylesheets/welcome.css.scss').read
    @welcome_view = Rails.root.join('app/views/welcome/_dashboard.html.erb').read
  end

  test 'mobile column state is persisted and restored from localStorage' do
    assert_includes @source, "const STORAGE_KEY = 'portalMobileActiveColumn';"
    assert_includes @source, 'window.localStorage.setItem(STORAGE_KEY, String(index));'
    assert_includes @source, 'const raw = window.localStorage.getItem(STORAGE_KEY);'
  end

  test 'invalid restored value falls back to first column' do
    assert_includes @source, 'Number.isNaN(restored) || restored < 0 || restored >= colCount'
    assert_includes @source, 'activateColumn($portal, $tabs, 0);'
  end

  test 'persistence and restore are guarded by mobile viewport check' do
    assert_includes @source, "window.matchMedia('(max-width: 767px)').matches"
    assert_match(/const mobile = isMobileViewport\(\).*window\.localStorage\.setItem/m, @source)
  end

  test 'activateColumn restores per-column scroll position on mobile' do
    assert_includes @source, 'const columnScrollPositions = {};'
    assert_match(/if \(mobile\) \{\s*window\.scrollTo\(0, columnScrollPositions\[index\]/m, @source)
    assert_match(/columnScrollPositions\[parseActiveColumnIndexFromPortal\(\$portal\)\] = window\.scrollY/m, @source)
  end

  test 'tab click and swipe both use shared activateColumn flow' do
    assert_includes @source, 'const activateColumn = function($portal, $tabs, index) {'
    assert_includes @source, "const index = parseInt($btn.attr('data-portal-column-index'), 10);"
    assert_includes @source, "const $tabs = $btn.closest('.portal-column-tabs');"
    assert_includes @source, "const $portal = $tabs.next('.portal');"
    assert_match(/\$root\.on\('click', '\.portal-column-tab'.*activateColumn\(\$portal, \$tabs, index\)/m, @source)
    assert_match(/if \(newIndex !== currentIndex\) \{\s*activateColumn\(\$portal, \$tabs, newIndex\);/m, @source)
  end

  test 'swipe works when column tab buttons are not in the DOM' do
    assert_includes @source, 'parseActiveColumnIndexFromPortal'
    assert_includes @source, 'portalColumnCount($portal)'
    assert_includes @source, 'if (colCount < 2) return;'
  end

  test 'activateColumn keeps tab ui and portal state synchronized' do
    assert_includes @source, 'if ($tabs.length) {'
    assert_includes @source, "$tabs.find('.portal-column-tab').each(function() {"
    assert_includes @source, "$t.toggleClass('portal-column-tab--active', active);"
    assert_includes @source, "$t.attr('aria-selected', active ? 'true' : 'false');"
    assert_includes @source, "return c && !/^portal--column-active-\\d+$/.test(c);"
    assert_includes @source, "base.push('portal--column-active-' + index);"
    assert_includes @source, 'syncPortalClasses($portal, index);'
  end

  test 'first paint can use prehydrated index from localStorage' do
    assert_includes @welcome_stylesheet, 'var(--portal-active-index, var(--portal-initial-active-index, 0))'
    assert_includes @welcome_view, "window.localStorage.getItem('portalMobileActiveColumn');"
    assert_includes @welcome_view, "window.matchMedia('(max-width: 767px)').matches"
    assert_includes @welcome_view, "document.documentElement.style.setProperty('--portal-initial-active-index', String(restored));"
  end

  test 'activateColumn calls portalLazy loadColumn on mobile' do
    assert_match(
      /const activateColumn = function.*?window\.portalLazy\.loadColumn\(index\)/m,
      @source
    )
  end
end
