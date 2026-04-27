$(document).ready(() => {
  $(document).on('blur', '#bookmark_url', function() {
    const urlValue = $.trim($(this).val());
    if (urlValue === '') {
      return;
    }

    $.get('/bookmarks/fetch_title', { url: urlValue })
      .done((title) => {
        const t = $.trim(title);
        if (t === '') {
          return;
        }
        const $titleField = $('#bookmark_title');
        if ($.trim($titleField.val()) === '') {
          $titleField.val(t);
        }
      })
      .fail(function() {
        // silent -- do nothing
      });
  });
});
