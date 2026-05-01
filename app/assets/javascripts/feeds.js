// Sprockets bundle: share namespace for load order (no new globals).
window.feeds = window.feeds || {};
// NOTE: `feeds` is a snapshot of the window.feeds reference at parse time.
// window.feeds remains the authoritative global; never reassign it in another
// file or the alias here will become stale.
const feeds = window.feeds;

feeds.get_feed_title = function(button) {
  const form = $(button).closest('form');

  const url = form.find('input[name*="feed_url"]').val();
  if (url === '') {
    alert($(button).data('feedUrlRequiredMessage'));
    return;
  }
  
  const params = form.serializeArray();
  for (let i = 0; i < params.length; i ++) {
    if (params[i].name === 'id') {
      params[i].value = '';  // omit id so server treats this as a new record
    } else if (params[i].name === '_method') {
      params[i].value = 'post';
    }
  }

  $.post($(button).data('url'), params, (title) => {
    if ($.trim(title) === '') {
      alert($(button).data('feedFetchFailedMessage'));
      return;
    }
    form.find('input[name*="title"]').val(title);
  });
};
