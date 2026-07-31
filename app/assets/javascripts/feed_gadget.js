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

  // document 委譲の stopPropagation だけでは touch-punch が先に touchstart を
  // 握って click を潰す。portal_gadget_sort.js のヘッダリンク対策と同様に
  // .gadgets へ直接 bind して stopImmediatePropagation する（#260731-u3v）。
  function bindFeedHeaderSortGuard() {
    const $gadgets = $('.gadgets');
    if (!$gadgets.length) return;

    $gadgets
      .off('mousedown.feedGadgetHeader touchstart.feedGadgetHeader', FEED_HEADER_SELECTOR)
      .on('mousedown.feedGadgetHeader touchstart.feedGadgetHeader', FEED_HEADER_SELECTOR, function(e) {
        if ($(e.target).closest('.feed-gadget-settings-link').length) return;
        e.stopImmediatePropagation();
      });
  }

  bindFeedHeaderSortGuard();

  // モバイルでヘッダ（アイコン/タイトル）をタップすると「設定」リンクの表示を切り替える。
  // フィードだけヘッダタイトルが外部サイトへのリンクのため、初回タップでは遷移を
  // 抑止する（表示中にサイト名を再タップしたときだけリンク先へ進める）。
  $(document).on('click', FEED_HEADER_SELECTOR, function(e) {
    if (!MOBILE_MQ.matches) return;
    if ($(e.target).closest('.feed-gadget-settings-link').length) return;

    const $header = $(this);
    const $siteLink = $(e.target).closest('.gadget-title-text a');
    const actionsVisible = $header.hasClass('title--gadget-actions-visible');

    if ($siteLink.length && actionsVisible) {
      $header.removeClass('title--gadget-actions-visible');
      return;
    }

    e.preventDefault();
    e.stopPropagation();
    $header.toggleClass('title--gadget-actions-visible');
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
