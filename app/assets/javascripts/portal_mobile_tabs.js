$(function() {
  const $root = $(document);
  const STORAGE_KEY = 'portalMobileActiveColumn';
  const isMobileViewport = function() {
    if (!window.matchMedia) return false;
    return window.matchMedia('(max-width: 767px)').matches;
  };

  const syncPortalClasses = function($portal, index) {
    const base = ($portal.attr('class') || '').split(/\s+/).filter(function(c) {
      return c && !/^portal--column-active-\d+$/.test(c);
    });
    base.push('portal--column-active-' + index);
    $portal.attr('class', base.join(' ').trim());
  };

  const activateColumn = function($portal, $tabs, index) {
    $tabs.find('.portal-column-tab').each(function() {
      const $t = $(this);
      const i = parseInt($t.attr('data-portal-column-index'), 10);
      const active = i === index;
      $t.toggleClass('portal-column-tab--active', active);
      $t.attr('aria-selected', active ? 'true' : 'false');
    });

    syncPortalClasses($portal, index);
    if (isMobileViewport()) {
      window.localStorage.setItem(STORAGE_KEY, String(index));
    }
  };

  $root.on('click', '.portal-column-tab', function(e) {
    e.preventDefault();
    const $btn = $(this);
    const index = parseInt($btn.attr('data-portal-column-index'), 10);
    if (Number.isNaN(index)) return;

    const $tabs = $btn.closest('.portal-column-tabs');
    const $portal = $tabs.next('.portal');
    if (!$portal.length) return;
    activateColumn($portal, $tabs, index);
  });

  document.querySelectorAll('.portal').forEach(function(portalEl) {
    let startX = 0;
    let startY = 0;
    let scrollIntent = false;
    let totalDx = 0;

    portalEl.addEventListener(
      'touchstart',
      function(e) {
        const t = e.touches[0];
        if (!t) return;
        startX = t.clientX;
        startY = t.clientY;
        scrollIntent = false;
        totalDx = 0;
      },
      { passive: true }
    );

    portalEl.addEventListener(
      'touchmove',
      function(e) {
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

    portalEl.addEventListener('touchend', function() {
      if (scrollIntent || Math.abs(totalDx) < 50) return;

      const $portal = $(portalEl);
      const $tabs = $portal.prev('.portal-column-tabs');
      if (!$tabs.length) return;

      const $activeTab = $tabs.find('.portal-column-tab--active');
      const currentIndex = parseInt($activeTab.attr('data-portal-column-index'), 10);
      if (Number.isNaN(currentIndex)) return;

      const colCount = $tabs.find('.portal-column-tab').length;
      const direction = totalDx < 0 ? 1 : -1;
      const newIndex = Math.min(Math.max(currentIndex + direction, 0), colCount - 1);
      if (newIndex !== currentIndex) {
        activateColumn($portal, $tabs, newIndex);
      }
    });
  });

  if (isMobileViewport()) {
    $('.portal').each(function() {
      const $portal = $(this);
      const $tabs = $portal.prev('.portal-column-tabs');
      if (!$tabs.length) return;
      const colCount = $tabs.find('.portal-column-tab').length;
      const raw = window.localStorage.getItem(STORAGE_KEY);
      const restored = parseInt(raw, 10);
      if (Number.isNaN(restored) || restored < 0 || restored >= colCount) {
        activateColumn($portal, $tabs, 0);
        return;
      }
      activateColumn($portal, $tabs, restored);
    });
  }
});
