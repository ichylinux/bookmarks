// Sprockets bundle: share namespace for load order (no new globals).
window.portalLazy = window.portalLazy || {};
// NOTE: `portalLazy` is a snapshot of the window.portalLazy reference at parse time.
// window.portalLazy remains the authoritative global; never reassign it in another
// file or the alias here will become stale.
const portalLazy = window.portalLazy;

(function() {
  const isMobileViewport = function() {
    if (!window.matchMedia) return false;
    return window.matchMedia('(max-width: 767px)').matches;
  };

  const rawIndex = document.documentElement.style.getPropertyValue('--portal-initial-active-index');
  const parsed = parseInt(rawIndex, 10);
  const initialColumnIndex = (Number.isNaN(parsed) || parsed < 0) ? 0 : parsed;

  const queues = {};
  const loadedColumns = {};

  portalLazy.register = function(columnIndex, loadFn) {
    if (!isMobileViewport()) {
      loadFn();
      return;
    }
    if (loadedColumns[columnIndex]) {
      loadFn();
      return;
    }
    queues[columnIndex] = queues[columnIndex] || [];
    queues[columnIndex].push(loadFn);
    if (columnIndex === initialColumnIndex) {
      portalLazy.loadColumn(columnIndex);
    }
  };

  portalLazy.loadColumn = function(index) {
    if (loadedColumns[index]) return;
    loadedColumns[index] = true;
    const fns = queues[index] || [];
    for (let i = 0; i < fns.length; i++) {
      fns[i]();
    }
  };
})();
