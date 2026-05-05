$(function() {
  $(document).on('click', '[data-dismiss-flash]', function(e) {
    e.preventDefault();
    $(this).closest('.flash-message').remove();
  });
});
