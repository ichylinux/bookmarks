(function () {
  $(document).on('click.visitedLinks', '.gadget:not(#bookmark_gadget):not(#todo) ol li a[href]', function () {
    const url = this.href.replace(/#.*$/, '');
    $(this).addClass('link--visited');
    const gadget = $(this).closest('.gadget');
    const gadgetId = gadget.attr('id') || '';
    const title = $(this).text().trim();
    if (gadgetId.indexOf('feed_') === 0) {
      $.post('/visited_links', { url: url, title: title, source: 'feed', gadget_id: gadgetId });
    } else if (gadgetId.indexOf('x_account_') === 0) {
      $.post('/visited_links', { url: url, title: title, source: 'x', gadget_id: gadgetId });
    } else if (gadgetId.indexOf('mastodon_account_') === 0) {
      $.post('/visited_links', { url: url, title: title, source: 'mastodon', gadget_id: gadgetId });
    } else {
      $.post('/visited_links', { url: url });
    }
  });
})();
