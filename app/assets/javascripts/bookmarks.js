var bookmarks = {};

$(document).ready(function() {
  $(document).on('blur', '#bookmark_url', function() {
    var urlValue = $.trim($(this).val());
    if (urlValue === '') {
      return;
    }

    $.get('/bookmarks/fetch_title', { url: urlValue })
      .done(function(title) {
        title = $.trim(title);
        if (title === '') {
          return;
        }
        var $titleField = $('#bookmark_title');
        if ($.trim($titleField.val()) === '') {
          $titleField.val(title);
        }
      })
      .fail(function() {
        // silent -- do nothing
      });
  });
});
