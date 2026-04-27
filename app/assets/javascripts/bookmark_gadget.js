// ブックマークガジェットのフォルダ開閉機能
$(document).ready(() => {
  const STORAGE_KEY = 'bookmark_expanded_folders';
  
  // localStorageから展開状態を取得
  function getExpandedFolders() {
    const stored = localStorage.getItem(STORAGE_KEY);
    if (!stored) return [];
    try {
      const parsed = JSON.parse(stored);
      return Array.isArray(parsed) ? parsed : [];
    } catch (_e) {
      return [];
    }
  }
  
  // localStorageに展開状態を保存
  function saveExpandedFolders(folderIds) {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(folderIds));
  }
  
  // フォルダを展開
  function expandFolder(folderId) {
    const $bookmarks = $('#folder-' + folderId);
    const $header = $('.folder-header[data-folder-id="' + folderId + '"]');
    const $toggle = $header.find('.folder-toggle');
    
    if (!$bookmarks.is(':visible')) {
      $bookmarks.show();
      $toggle.text('▼');
    }
  }
  
  // ページ読み込み時に保存された展開状態を復元
  const expandedFolders = getExpandedFolders();
  expandedFolders.forEach(function(folderId) {
    expandFolder(folderId);
  });
  
  // フォルダヘッダーのクリックイベント
  $('.folder-header').on('click', function() {
    const $header = $(this);
    const folderId = $header.data('folder-id');
    const $bookmarks = $('#folder-' + folderId);
    const $toggle = $header.find('.folder-toggle');
    
    const expandedFolders = getExpandedFolders();
    const index = expandedFolders.indexOf(folderId.toString());
    
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
