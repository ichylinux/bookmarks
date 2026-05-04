// Sprockets bundle: share namespace for load order (no new globals).
window.feeds = window.feeds || {};
// NOTE: `feeds` is a snapshot of the window.feeds reference at parse time.
// window.feeds remains the authoritative global; never reassign it in another
// file or the alias here will become stale.
const feeds = window.feeds;

feeds.fetch_title = function(button) {
  const form = $(button).closest('form');
  const fetchPath = $(button).data('url');
  const feedUrl = $.trim(form.find('input[name*="feed_url"]').val() || '');
  if (feedUrl === '') {
    alert($(button).data('feedUrlRequiredMessage'));
    return;
  }

  $.get(fetchPath, { feed_url: feedUrl }, (title) => {
    const t = $.trim(title);
    if (t === '') {
      alert($(button).data('feedFetchFailedMessage'));
      return;
    }
    form.find('input[name*="title"]').val(t);
  }).fail(function() {
    alert($(button).data('feedFetchFailedMessage'));
  });
};
