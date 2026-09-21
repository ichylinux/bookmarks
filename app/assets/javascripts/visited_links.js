(function () {
  $(document).on('click.visitedLinks', '.gadget:not(#bookmark_gadget):not(#todo) ol li a[href]', function () {
    const url = this.href.replace(/#.*$/, '');
    $(this).addClass('link--visited');
    const gadget = $(this).closest('.gadget');
    const gadgetId = gadget.attr('id') || '';
    if (gadgetId.indexOf('feed_') === 0) {
      const title = $(this).text().trim();
      $.post('/visited_links', { url: url, title: title, source: 'feed' });
    } else {
      $.post('/visited_links', { url: url });
    }
  });
})();
