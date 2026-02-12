// ブックマークガジェットのフォルダ開閉機能
$(document).ready(function() {
  $('.folder-header').on('click', function() {
    var $header = $(this);
    var folderId = $header.data('folder-id');
    var $bookmarks = $('#folder-' + folderId);
    var $toggle = $header.find('.folder-toggle');
    
    if ($bookmarks.is(':visible')) {
      $bookmarks.slideUp();
      $toggle.text('▶');
    } else {
      $bookmarks.slideDown();
      $toggle.text('▼');
    }
  });
});
