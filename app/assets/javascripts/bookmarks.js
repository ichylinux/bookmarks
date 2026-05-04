window.bookmarks = window.bookmarks || {};
const bookmarks = window.bookmarks;

function requestBookmarkTitleFromUrl(fetchPath, url) {
  return $.get(fetchPath, { url: $.trim(url) });
}

bookmarks.fetch_title_from_url = function(button) {
  const form = $(button).closest('form');
  const fetchPath = $(button).data('url');
  const url = $.trim(form.find('#bookmark_url').val() || '');
  if (url === '') {
    alert($(button).data('bookmarkUrlRequiredMessage'));
    return;
  }

  requestBookmarkTitleFromUrl(fetchPath, url)
    .done((title) => {
      const t = $.trim(title);
      if (t === '') {
        alert($(button).data('bookmarkTitleFetchFailedMessage'));
        return;
      }
      form.find('#bookmark_title').val(t);
    })
    .fail(function() {
      alert($(button).data('bookmarkTitleFetchFailedMessage'));
    });
};
