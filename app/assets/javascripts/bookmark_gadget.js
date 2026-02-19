// ブックマークガジェットのフォルダ開閉機能
$(document).ready(function() {
  var STORAGE_KEY = 'bookmark_expanded_folders';
  
  // localStorageから展開状態を取得
  function getExpandedFolders() {
    var stored = localStorage.getItem(STORAGE_KEY);
    return stored ? JSON.parse(stored) : [];
  }
  
  // localStorageに展開状態を保存
  function saveExpandedFolders(folderIds) {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(folderIds));
  }
  
  // フォルダを展開
  function expandFolder(folderId) {
    var $bookmarks = $('#folder-' + folderId);
    var $header = $('.folder-header[data-folder-id="' + folderId + '"]');
    var $toggle = $header.find('.folder-toggle');
    
    if (!$bookmarks.is(':visible')) {
      $bookmarks.show();
      $toggle.text('▼');
    }
  }
  
  // フォルダを折りたたみ
  function collapseFolder(folderId) {
    var $bookmarks = $('#folder-' + folderId);
    var $header = $('.folder-header[data-folder-id="' + folderId + '"]');
    var $toggle = $header.find('.folder-toggle');
    
    if ($bookmarks.is(':visible')) {
      $bookmarks.hide();
      $toggle.text('▶');
    }
  }
  
  // ページ読み込み時に保存された展開状態を復元
  var expandedFolders = getExpandedFolders();
  expandedFolders.forEach(function(folderId) {
    expandFolder(folderId);
  });
  
  // フォルダヘッダーのクリックイベント
  $('.folder-header').on('click', function() {
    var $header = $(this);
    var folderId = $header.data('folder-id');
    var $bookmarks = $('#folder-' + folderId);
    var $toggle = $header.find('.folder-toggle');
    
    var expandedFolders = getExpandedFolders();
    var index = expandedFolders.indexOf(folderId.toString());
    
    if ($bookmarks.is(':visible')) {
      $bookmarks.slideUp();
      $toggle.text('▶');
      // localStorageから削除
      if (index > -1) {
        expandedFolders.splice(index, 1);
        saveExpandedFolders(expandedFolders);
      }
    } else {
      $bookmarks.slideDown();
      $toggle.text('▼');
      // localStorageに追加
      if (index === -1) {
        expandedFolders.push(folderId.toString());
        saveExpandedFolders(expandedFolders);
      }
    }
  });
});
