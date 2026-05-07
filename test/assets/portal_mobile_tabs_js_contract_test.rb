# frozen_string_literal: true

require 'test_helper'

class PortalMobileTabsJsContractTest < ActiveSupport::TestCase
  def setup
    @source = Rails.root.join('app/assets/javascripts/portal_mobile_tabs.js').read
    @portal_section = Rails.root.join('app/views/welcome/_portal_column_section.html.erb').read
    @welcome_stylesheet = Rails.root.join('app/assets/stylesheets/welcome.css.scss').read
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
    assert_match(/if \(isMobileViewport\(\)\) \{\s*window\.localStorage\.setItem/m, @source)
  end

  test 'tab click and swipe both use shared activateColumn flow' do
    assert_includes @source, 'const activateColumn = function($portal, $tabs, index) {'
    assert_includes @source, "const index = parseInt($btn.attr('data-portal-column-index'), 10);"
    assert_includes @source, "const $tabs = $btn.closest('.portal-column-tabs');"
    assert_includes @source, "const $portal = $tabs.next('.portal');"
    assert_match(/\$root\.on\('click', '\.portal-column-tab'.*activateColumn\(\$portal, \$tabs, index\)/m, @source)
    assert_match(/if \(newIndex !== currentIndex\) \{\s*activateColumn\(\$portal, \$tabs, newIndex\);/m, @source)
  end

  test 'activateColumn keeps tab ui and portal state synchronized' do
    assert_includes @source, "$tabs.find('.portal-column-tab').each(function() {"
    assert_includes @source, "$t.toggleClass('portal-column-tab--active', active);"
    assert_includes @source, "$t.attr('aria-selected', active ? 'true' : 'false');"
    assert_includes @source, "return c && !/^portal--column-active-\\d+$/.test(c);"
    assert_includes @source, "base.push('portal--column-active-' + index);"
    assert_includes @source, 'syncPortalClasses($portal, index);'
  end

  test 'initial restore is rendered without transition animation' do
    assert_includes @portal_section, 'portal--initializing'
    assert_includes @welcome_stylesheet, '.portal--initializing .portal-track'
    assert_includes @welcome_stylesheet, 'transition: none;'
    assert_includes @source, "if ($portal.hasClass('portal--initializing')) {"
    assert_includes @source, 'window.requestAnimationFrame(function() {'
    assert_includes @source, "$portal.removeClass('portal--initializing');"
  end
end
