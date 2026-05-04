$(function() {
  const $root = $(document);

  const syncPortalClasses = function($portal, index) {
    const base = ($portal.attr('class') || '').split(/\s+/).filter(function(c) {
      return c && !/^portal--column-active-\d+$/.test(c);
    });
    base.push('portal--column-active-' + index);
    $portal.attr('class', base.join(' ').trim());
  };

  $root.on('click', '.portal-column-tab', function(e) {
    e.preventDefault();
    const $btn = $(this);
    const index = parseInt($btn.attr('data-portal-column-index'), 10);
    if (Number.isNaN(index)) return;

    const $tabs = $btn.closest('.portal-column-tabs');
    const $portal = $tabs.next('.portal');
    if (!$portal.length) return;

    $tabs.find('.portal-column-tab').each(function() {
      const $t = $(this);
      const i = parseInt($t.attr('data-portal-column-index'), 10);
      const active = i === index;
      $t.toggleClass('portal-column-tab--active', active);
      $t.attr('aria-selected', active ? 'true' : 'false');
    });

    syncPortalClasses($portal, index);
  });
});
