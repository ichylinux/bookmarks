require 'test_helper'

class PortalGadgetSortJsContractTest < ActiveSupport::TestCase
  def setup
    @source = Rails.root.join('app/assets/javascripts/portal_gadget_sort.js').read
    @touch_punch = Rails.root.join('vendor/assets/javascripts/jquery.ui.touch-punch.js').read
    @dashboard = Rails.root.join('app/views/welcome/_dashboard.html.erb').read
    @mobile_tabs = Rails.root.join('app/assets/javascripts/portal_mobile_tabs.js').read
    @welcome_stylesheet = Rails.root.join('app/assets/stylesheets/welcome.css.scss').read
  end

  test 'requires touch-punch for mobile sortable' do
    assert_includes @source, '//= require jquery.ui.touch-punch'
    assert_includes @touch_punch, '$.support.touch'
  end

  test 'exposes init and uses long-press delay on mobile' do
    assert_includes @source, 'window.portalGadgetSort.init'
    assert_includes @source, "const MOBILE_MEDIA = '(max-width: 767px)'"
    assert_includes @source, 'window.matchMedia(MOBILE_MEDIA).matches'
    assert_includes @source, 'LONG_PRESS_MS = 2000'
    assert_includes @source, 'sortableOptions.delay = LONG_PRESS_MS'
    assert_includes @source, "handle: 'div.title'"
  end

  test 'enters expanded column mode while sorting on mobile' do
    assert_includes @source, 'portal--gadget-sorting'
    assert_includes @source, 'enterMobileSortMode'
    assert_includes @welcome_stylesheet, '.portal.portal--gadget-sorting .portal-track'
    assert_includes @welcome_stylesheet, 'transform: none !important'
  end

  test 'dashboard delegates to portalGadgetSort' do
    assert_includes @dashboard, 'window.portalGadgetSort.init'
    assert_includes @dashboard, 'collectParams: collect_portal_layout_params'
    refute_match(/\$\(['"]\.gadgets['"]\)\.sortable/, @dashboard)
  end

  test 'portal mobile swipe is disabled during gadget sorting' do
    assert_includes @mobile_tabs, "portalEl.classList.contains('portal--gadget-sorting')"
  end
end
