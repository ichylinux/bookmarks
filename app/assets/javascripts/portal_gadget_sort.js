//= require jquery.ui.touch-punch

(function() {
  window.portalGadgetSort = window.portalGadgetSort || {};

  const MOBILE_MEDIA = '(max-width: 767px)';
  const LONG_PRESS_MS = 2000;
  const DRAG_DISTANCE_PX = 12;

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

    const mobile = isMobileViewport();
    const sortableOptions = {
      connectWith: '.gadgets',
      handle: '.gadget-title-drag-handle',
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
