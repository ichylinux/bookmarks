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
    if (typeof window.notePane !== 'undefined') window.notePane.hide();
    activateColumn($portal, $tabs, index);
  });

  if (isMobileViewport()) {
    $('.portal').each(function () {
      const $portal = $(this);
      const $tabs = $portal.prev('.portal-column-tabs');
      const colCount = portalColumnCount($portal);
      if (colCount < 1) return;

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
