$(function () {
  const $root = $(document);
  const STORAGE_KEY = 'portalMobileActiveColumn';
  const isMobileViewport = function () {
    if (!window.matchMedia) return false;
    return window.matchMedia('(max-width: 767px)').matches;
  };

  const syncPortalClasses = function ($portal, index) {
    const base = ($portal.attr('class') || '').split(/\s+/).filter(function (c) {
      return c && !/^portal--column-active-\d+$/.test(c);
    });
    base.push('portal--column-active-' + index);
    $portal.attr('class', base.join(' ').trim());
  };

  const parseActiveColumnIndexFromPortal = function ($portal) {
    const m = ($portal.attr('class') || '').match(/portal--column-active-(\d+)/);
    if (!m) return 0;
    const n = parseInt(m[1], 10);
    return Number.isNaN(n) ? 0 : n;
  };

  const portalColumnCount = function ($portal) {
    return $portal.find('.portal-column').length;
  };

  const columnScrollPositions = {};

  const activateColumn = function ($portal, $tabs, index) {
    if ($tabs.length) {
      $tabs.find('.portal-column-tab').each(function () {
        const $t = $(this);
        const i = parseInt($t.attr('data-portal-column-index'), 10);
        const active = i === index;
        $t.toggleClass('portal-column-tab--active', active);
        $t.attr('aria-selected', active ? 'true' : 'false');
      });
    }

    const mobile = isMobileViewport();
    if (mobile) {
      columnScrollPositions[parseActiveColumnIndexFromPortal($portal)] = window.scrollY;
    }

    syncPortalClasses($portal, index);
    $portal[0].style.setProperty('--portal-active-index', index);
    if (mobile) {
      window.scrollTo(0, columnScrollPositions[index] || 0);
      window.localStorage.setItem(STORAGE_KEY, String(index));
      window.portalLazy.loadColumn(index);
    }
  };

  $root.on('click', '.portal-column-tab', function (e) {
    e.preventDefault();
    const $btn = $(this);
    const index = parseInt($btn.attr('data-portal-column-index'), 10);
    if (Number.isNaN(index)) return;

    const $tabs = $btn.closest('.portal-column-tabs');
    const $portal = $tabs.next('.portal');
    if (!$portal.length) return;
    // Ensure note pane is hidden when activating a column tab
    if (typeof window.notePane !== 'undefined') window.notePane.hide();
    activateColumn($portal, $tabs, index);
  });

  const handleSwipeEnd = function (portalEl, totalDx, scrollIntent) {
    if (portalEl.classList.contains('portal--gadget-sorting')) return;
    if (scrollIntent || Math.abs(totalDx) < 50) return;

    const $portal = $(portalEl);
    const $tabs = $portal.prev('.portal-column-tabs');
    const colCount = portalColumnCount($portal);
    const noteInCycle =
      typeof window.notePane !== 'undefined' && window.notePane.available();
    // cycleLength = columns + note slot (when note is available)
    const cycleLength = colCount + (noteInCycle ? 1 : 0);
    // Note sentinel index is colCount (the last slot in the cycle)
    if (cycleLength < 2) return;

    let currentIndex;
    if (noteInCycle && window.notePane.isVisible()) {
      currentIndex = colCount; // currently on note pane
    } else if ($tabs.length) {
      const $activeTab = $tabs.find('.portal-column-tab--active');
      currentIndex = parseInt($activeTab.attr('data-portal-column-index'), 10);
      if (Number.isNaN(currentIndex)) return;
    } else {
      currentIndex = parseActiveColumnIndexFromPortal($portal);
    }

    const direction = totalDx < 0 ? 1 : -1;
    // Modular wrap-around — replaces Math.min/Math.max clamping
    const newIndex =
      ((currentIndex + direction) % cycleLength + cycleLength) % cycleLength;

    if (noteInCycle && newIndex === colCount) {
      // Swiped to note pane: reveal it and deactivate all column tabs
      window.notePane.show();
      if ($tabs.length) {
        $tabs.find('.portal-column-tab').each(function () {
          $(this).toggleClass('portal-column-tab--active', false);
          $(this).attr('aria-selected', 'false');
        });
      }
      // Persist note sentinel so reload restores the note pane
      window.localStorage.setItem(STORAGE_KEY, 'note');
    } else {
      // Swiped to a column: hide note pane first, then activate column
      if (typeof window.notePane !== 'undefined') window.notePane.hide();
      activateColumn($portal, $tabs, newIndex);
    }
  };

  // Swipe gesture detection is bound once at the document level rather than on
  // the .portal element. When the note pane is visible the home panel holding
  // .portal is display:none, so a .portal-scoped listener never fires; and the
  // note pane itself can be shorter than the viewport, leaving dead zones. A
  // single document-level listener captures the swipe wherever it happens and
  // resolves the (possibly hidden) portal lazily inside the handler.
  const resolvePortalEl = function () {
    return document.querySelector('.portal');
  };
  const gestureBlocked = function (portalEl) {
    if (!portalEl) return true;
    if (portalEl.classList.contains('portal--gadget-sorting')) return true;
    // Don't hijack swipes while the slide-in drawer menu is open.
    return document.body.classList.contains('drawer-open');
  };

  let startX = 0;
  let startY = 0;
  let scrollIntent = false;
  let totalDx = 0;

  document.addEventListener(
    'touchstart',
    function (e) {
      if (gestureBlocked(resolvePortalEl())) return;
      const t = e.touches[0];
      if (!t) return;
      startX = t.clientX;
      startY = t.clientY;
      scrollIntent = false;
      totalDx = 0;
    },
    { passive: true }
  );

  document.addEventListener(
    'touchmove',
    function (e) {
      if (gestureBlocked(resolvePortalEl())) return;
      if (scrollIntent) return;
      const t = e.touches[0];
      if (!t) return;
      const dx = t.clientX - startX;
      const dy = t.clientY - startY;
      if (Math.abs(dx) + Math.abs(dy) < 10) return;
      if (Math.abs(dy) > Math.abs(dx)) {
        scrollIntent = true;
        return;
      }
      e.preventDefault();
      totalDx = dx;
    },
    { passive: false }
  );

  document.addEventListener('touchend', function () {
    const portalEl = resolvePortalEl();
    if (gestureBlocked(portalEl)) return;
    handleSwipeEnd(portalEl, totalDx, scrollIntent);
  });

  if (isMobileViewport()) {
    $('.portal').each(function () {
      const $portal = $(this);
      const $tabs = $portal.prev('.portal-column-tabs');
      const colCount = portalColumnCount($portal);
      if (colCount < 1) return;

      const noteInCycle =
        typeof window.notePane !== 'undefined' && window.notePane.available();
      const raw = window.localStorage.getItem(STORAGE_KEY);

      // 'note' is a valid stored sentinel — restore note pane directly.
      // Number.parseInt('note', 10) is NaN so the NaN guard below would also
      // catch it, but we check explicitly first to avoid falling back to column 0.
      if (raw === 'note' && noteInCycle) {
        window.notePane.show();
        // Deactivate all column tabs while note pane is active
        if ($tabs.length) {
          $tabs.find('.portal-column-tab').each(function () {
            $(this).toggleClass('portal-column-tab--active', false);
            $(this).attr('aria-selected', 'false');
          });
        }
        return;
      }

      const restored = parseInt(raw, 10);
      if (Number.isNaN(restored) || restored < 0 || restored >= colCount) {
        activateColumn($portal, $tabs, 0);
        return;
      }
      activateColumn($portal, $tabs, restored);
    });
  }
});
