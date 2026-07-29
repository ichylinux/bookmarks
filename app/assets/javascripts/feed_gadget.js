// フィードガジェットの設定ダイアログ
$(document).ready(() => {
  const FEED_HEADER_SELECTOR = '.title--gadget-with-icon[data-gadget-icon="feed"]';

  function reloadFeedGadget(feedId, feedUrl) {
    $.get(feedUrl, { format: 'html' }, function(html) {
      $('#feed_' + feedId).html(html);
    });
  }

  // mousedown/touchstart のバブリングを止め、jQuery UI sortable（モバイルでは
  // touch-punch）がガジェット並べ替えドラッグの開始としてこのタップを捕捉しない
  // ようにする（bookmark_gadget.js / todos.js と同じ手当て）。
  $(document).on('mousedown touchstart', '.feed-gadget-settings-link', function(e) {
    e.stopPropagation();
  });

  $(document).on('mousedown touchstart', FEED_HEADER_SELECTOR, function(e) {
    if ($(e.target).closest('.feed-gadget-settings-link').length) return;
    e.stopPropagation();
  });

  // モバイルでヘッダ（アイコン/タイトル）をタップすると「設定」リンクの表示を切り替える。
  $(document).on('click', FEED_HEADER_SELECTOR, function(e) {
    if (!MOBILE_MQ.matches) return;
    if ($(e.target).closest('.feed-gadget-settings-link').length) return;
    e.stopPropagation();
    $(this).toggleClass('title--gadget-actions-visible');
  });

  $(document).on('touchstart', function(e) {
    if (!MOBILE_MQ.matches) return;
    if ($(e.target).closest(FEED_HEADER_SELECTOR).length) return;
    $(FEED_HEADER_SELECTOR).removeClass('title--gadget-actions-visible');
  });

  $(document).on('click', '.feed-gadget-settings-link', function(e) {
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

  $(document).on('click', '.feed-settings-dialog', function(e) {
    if (e.target === this) this.close();
  });

  $(document).on('ajax:success', '.feed-settings-dialog__form', function() {
    const $form = $(this);
    const feedId = $form.data('feedId');
    const feedUrl = $form.data('feedUrl');
    const dialog = $form.closest('dialog')[0];

    if (dialog) dialog.close();

    if (feedId && feedUrl) reloadFeedGadget(feedId, feedUrl);
  });

  $(document).on('ajax:error', '.feed-settings-dialog__form', function(e) {
    const xhr = (e.originalEvent || e).detail[2];
    alert((xhr && xhr.responseText) || 'エラーが発生しました');
  });
});
