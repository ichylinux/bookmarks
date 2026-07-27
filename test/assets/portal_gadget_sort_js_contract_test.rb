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
    assert_includes @source, "handle: '.gadget-title-drag-handle'"
  end

  # ガジェットヘッダのリンク（フィードのサイト名 / Mastodon・X のアカウント名）は
  # ドラッグハンドルの内側にあるため、この 2 つの手当てが外れると「押してから離す
  # までに数 px 動くとリンクが開かない」状態に戻る。
  test 'header links are excluded from the sortable drag handle' do
    assert_includes @source, "const HEADER_LINK_SELECTOR = '.gadget-title-text a'"

    # (1) リンクの上ではドラッグを開始しない（デスクトップ: 1px 動くと sortable が
    #     ドラッグを始め preventClickEvent で click が潰される）
    assert_includes @source, "'input,textarea,button,select,option,' + HEADER_LINK_SELECTOR"
    assert_includes @source, 'cancel: SORTABLE_CANCEL'

    # (2) touch-punch は cancel を見ずに handle 判定だけで touchstart を握り
    #     preventDefault() するので、.gadgets に届く前に止める必要がある
    assert_match(
      /\$gadgets\.on\(\s*['"]mousedown touchstart['"],\s*HEADER_LINK_SELECTOR/,
      @source,
      'portal_gadget_sort.js must stop mousedown/touchstart on gadget header links before they ' \
      'reach the sortable element, otherwise touch-punch swallows the tap on mobile.'
    )
    assert_includes @source, 'e.stopImmediatePropagation()',
                    'stopPropagation is not enough — touch-punch and sortable bind directly on ' \
                    'the same .gadgets element, so remaining handlers there must be stopped too.'
  end

  test 'touch-punch only synthesizes a click when the finger did not move' do
    # 上記 (2) の前提。この分岐が変わったら header link の手当ても見直すこと。
    assert_includes @touch_punch, 'if (!this._touchMoved)'
    assert_includes @touch_punch, 'event.preventDefault();'
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
