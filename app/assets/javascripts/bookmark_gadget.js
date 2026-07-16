// ブックマークガジェットのフォルダ開閉機能 + 新規追加ダイアログ
$(document).ready(() => {
  const STORAGE_KEY = 'bookmark_expanded_folders';
  const BOOKMARK_HEADER_SELECTOR = '.title--gadget-with-icon[data-gadget-icon="bookmark"]';

  function getExpandedFolders() {
    const stored = localStorage.getItem(STORAGE_KEY);
    if (!stored) return [];
    try {
      const parsed = JSON.parse(stored);
      return Array.isArray(parsed) ? parsed : [];
    } catch {
      return [];
    }
  }

  function saveExpandedFolders(folderIds) {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(folderIds));
  }

  function expandFolder(folderId) {
    const $bookmarks = $('#folder-' + folderId);
    const $header = $('.folder-header[data-folder-id="' + folderId + '"]');
    const $toggle = $header.find('.folder-toggle');

    if (!$bookmarks.is(':visible')) {
      $bookmarks.show();
      $toggle.addClass('is-expanded');
    }
  }

  function restoreExpandedFolders() {
    getExpandedFolders().forEach(function(folderId) {
      expandFolder(folderId);
    });
  }

  function reloadGadget(gadgetUrl, parentId) {
    $.get(gadgetUrl, { format: 'html' }, function(html) {
      const $fragment = $('<div>').html(html);
      $('#bookmark_gadget').replaceWith($fragment.find('#bookmark_gadget'));
      $('#bookmark-new-dialog').replaceWith($fragment.find('#bookmark-new-dialog'));
      restoreExpandedFolders();
      if (parentId) expandFolder(parentId);
    });
  }

  // 新規ブックマークダイアログ
  // mousedown/touchstart のバブリングを止め、jQuery UI sortable（モバイルでは
  // touch-punch）がガジェット並べ替えドラッグの開始としてこのタップを捕捉しない
  // ようにする（todos.js の .todo-gadget-new-link 対策と同じ手当て）。
  $(document).on('mousedown touchstart', '.bookmark-gadget-new-link', function(e) {
    e.stopPropagation();
  });

  // ヘッダのドラッグハンドル（.gadget-title-drag-handle）が touch-punch で
  // touchstart を捕捉すると「追加」表示切替のタップが effectively 無効になる。
  // 追加リンク自身のタップはここでは止めない。
  $(document).on('mousedown touchstart', BOOKMARK_HEADER_SELECTOR, function(e) {
    if ($(e.target).closest('.bookmark-gadget-new-link').length) return;
    e.stopPropagation();
  });

  // モバイルでヘッダ（アイコン/タイトル）をタップすると「追加」リンクの表示を
  // 切り替える（todos.js の title--gadget-actions-visible トグルと同じ挙動）。
  $(document).on('click', BOOKMARK_HEADER_SELECTOR, function(e) {
    if (!MOBILE_MQ.matches) return;
    if ($(e.target).closest('.bookmark-gadget-new-link').length) return;
    e.stopPropagation();
    $(this).toggleClass('title--gadget-actions-visible');
  });

  // ヘッダ外をタップしたら表示中の「追加」を閉じる。
  $(document).on('touchstart', function(e) {
    if (!MOBILE_MQ.matches) return;
    if ($(e.target).closest(BOOKMARK_HEADER_SELECTOR).length) return;
    $(BOOKMARK_HEADER_SELECTOR).removeClass('title--gadget-actions-visible');
  });

  $(document).on('click', '.bookmark-gadget-new-link', function(e) {
    e.preventDefault();
    const dialogId = $(this).data('dialog');
    const dialog = document.getElementById(dialogId);
    if (dialog) dialog.showModal();
  });

  $(document).on('click', '[data-dialog-close]', function() {
    const dialogId = $(this).data('dialogClose');
    const dialog = document.getElementById(dialogId);
    if (dialog) dialog.close();
  });

  $(document).on('click', '.bookmark-new-dialog', function(e) {
    if (e.target === this) this.close();
  });

  $(document).on('ajax:success', '.bookmark-new-dialog__form', function() {
    const $form = $(this);
    const dialog = document.getElementById('bookmark-new-dialog');
    const parentId = $form.find('[name="bookmark[parent_id]"]').val();
    const gadgetUrl = $form.data('gadgetUrl');

    if (dialog) dialog.close();
    $form[0].reset();

    if (gadgetUrl) reloadGadget(gadgetUrl, parentId || null);
  });

  $(document).on('ajax:error', '.bookmark-new-dialog__form', function(e) {
    const xhr = (e.originalEvent || e).detail[2];
    alert((xhr && xhr.responseText) || 'エラーが発生しました');
  });

  restoreExpandedFolders();

  $(document).on('click', '.folder-header', function() {
    const $header = $(this);
    const folderId = $header.data('folder-id');
    const $bookmarks = $('#folder-' + folderId);
    const $toggle = $header.find('.folder-toggle');

    const expandedFolders = getExpandedFolders();
    const index = expandedFolders.indexOf(folderId.toString());

    if ($bookmarks.is(':visible')) {
      $bookmarks.slideUp();
      $toggle.removeClass('is-expanded');
      if (index > -1) {
        expandedFolders.splice(index, 1);
        saveExpandedFolders(expandedFolders);
      }
    } else {
      $bookmarks.slideDown();
      $toggle.addClass('is-expanded');
      if (index === -1) {
        expandedFolders.push(folderId.toString());
        saveExpandedFolders(expandedFolders);
      }
    }
  });
});
