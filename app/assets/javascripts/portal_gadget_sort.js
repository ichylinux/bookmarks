//= require jquery.ui.touch-punch

(function() {
  window.portalGadgetSort = window.portalGadgetSort || {};

  const MOBILE_MEDIA = '(max-width: 767px)';
  const LONG_PRESS_MS = 2000;
  const DRAG_DISTANCE_PX = 12;

  // ガジェットヘッダのリンク（フィードのサイト名、Mastodon/X のアカウント名）は
  // ドラッグハンドル .gadget-title-drag-handle の内側にあるため、素のままだと
  // リンクを開くクリックが並べ替えドラッグに吸われる:
  //   - デスクトップ: 押してから離すまでに 1px でも動くと sortable がドラッグを
  //     開始し、jQuery UI mouse widget が preventClickEvent を立てて click を潰す。
  //   - モバイル: touch-punch が touchstart で preventDefault() するためネイティブ
  //     click が発生せず、代わりの合成 click は指が全く動かなかったときしか出ない
  //     （jquery.ui.touch-punch.js の `if (!this._touchMoved)`）。
  const HEADER_LINK_SELECTOR = '.gadget-title-text a';
  // jQuery UI sortable の cancel 既定値 + ヘッダリンク。リンクの上では
  // ドラッグそのものを開始させない（ハンドルはアイコンと余白側に残る）。
  const SORTABLE_CANCEL = 'input,textarea,button,select,option,' + HEADER_LINK_SELECTOR;

  const isMobileViewport = function() {
    if (!window.matchMedia) return false;
    return window.matchMedia(MOBILE_MEDIA).matches;
  };

  const scrollPortalToActiveColumn = function($portal) {
    const activeIndex = parseInt(
      ($portal[0].style.getPropertyValue('--portal-active-index') ||
        getComputedStyle($portal[0]).getPropertyValue('--portal-active-index') ||
        '0'),
      10
    );
    if (Number.isNaN(activeIndex)) return;

    const $column = $portal.find('.portal-column').eq(activeIndex);
    if (!$column.length) return;

    const portalEl = $portal[0];
    const columnLeft = $column[0].offsetLeft;
    portalEl.scrollLeft = Math.max(0, columnLeft - 8);
  };

  const enterMobileSortMode = function($portal) {
    $portal.addClass('portal--gadget-sorting');
    scrollPortalToActiveColumn($portal);
  };

  const exitMobileSortMode = function($portal) {
    $portal.removeClass('portal--gadget-sorting');
    $portal[0].scrollLeft = 0;
  };

  window.portalGadgetSort.init = function(options) {
    const $gadgets = $('.gadgets');
    if (!$gadgets.length || typeof $.fn.sortable !== 'function') return;

    // cancel だけではモバイルを救えない: touch-punch は cancel を見ずに
    // _mouseCapture（= handle 判定）だけで touchstart を握り、preventDefault() で
    // ネイティブ click を消してしまう。そこでヘッダリンク上の mousedown/touchstart
    // は touch-punch / sortable のハンドラに届く前に止める（todos.js・
    // bookmark_gadget.js のヘッダ対策と同じ手当て）。両ハンドラは .gadgets 自身に
    // 直接 bind されるため、同一要素上の後続ハンドラも止まる
    // stopImmediatePropagation が必要（jQuery は委譲ハンドラを直接ハンドラより
    // 先に実行するので、登録順に関わらずこちらが先に走る）。
    $gadgets.on('mousedown touchstart', HEADER_LINK_SELECTOR, function(e) {
      e.stopImmediatePropagation();
    });

    const mobile = isMobileViewport();
    const sortableOptions = {
      connectWith: '.gadgets',
      handle: '.gadget-title-drag-handle',
      cancel: SORTABLE_CANCEL,
      tolerance: 'pointer',
      start: function(_event, ui) {
        $(this).addClass('dragging');
        const $portal = ui.item.closest('.portal');
        if (isMobileViewport() && $portal.length) {
          enterMobileSortMode($portal);
        }
      },
      stop: function(_event, ui) {
        $(this).removeClass('dragging');
        const $portal = ui.item.closest('.portal');
        if ($portal.length) {
          exitMobileSortMode($portal);
        }
      },
      update: function() {
        if (typeof options.collectParams === 'function') {
          $.post(options.saveUrl, options.collectParams());
        }
      }
    };

    if (mobile) {
      sortableOptions.delay = LONG_PRESS_MS;
      sortableOptions.distance = DRAG_DISTANCE_PX;
    }

    $gadgets.sortable(sortableOptions);
  };
})();
