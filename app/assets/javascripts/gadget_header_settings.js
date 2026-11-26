// フィード・X・Mastodon ガジェットの設定ダイアログ
$(document).ready(() => {
  const SETTINGS_LINK_SELECTOR =
    '.feed-gadget-settings-link, .x-gadget-settings-link, .mastodon-gadget-settings-link';

  const HEADER_WITH_EXTERNAL_LINK = [
    {
      header: '.title--gadget-with-icon[data-gadget-icon="feed"]',
      settingsLink: '.feed-gadget-settings-link'
    },
    {
      header: '.title--gadget-with-icon[data-gadget-icon="x"]',
      settingsLink: '.x-gadget-settings-link'
    },
    {
      header: '.title--gadget-with-icon[data-gadget-icon="mastodon"]',
      settingsLink: '.mastodon-gadget-settings-link'
    }
  ];

  function reloadGadget($form) {
    const gadgetId = $form.data('gadgetId');
    const gadgetUrl = $form.data('gadgetUrl');
    const domPrefix = $form.data('gadgetDomPrefix');
    if (!gadgetId || !gadgetUrl || !domPrefix) return;

    $.get(gadgetUrl, { format: 'html' }, function(html) {
      $('#' + domPrefix + gadgetId).html(html);
    });
  }

  // 再読込（feeds#show）はリモートの RSS を取り直すため、応答まで数秒かかったり
  // 取得失敗で置き換え自体が起きなかったりする。保存したタイトルはその完了を
  // 待たずにヘッダへ反映する。
  function applyFeedTitle($form, feedId) {
    const title = $.trim($form.find('input[name="feed[title]"]').val() || '');
    if (title === '') return;

    const $titleText = $('#feed_' + feedId + ' .gadget-title-text');
    const $link = $titleText.find('a').first();
    if ($link.length) {
      $link.text(title);
    } else {
      $titleText.text(title);
    }
  }

  function reloadFeedGadget(feedId, feedUrl) {
    $.get(feedUrl, { format: 'html' }, function(html) {
      $('#feed_' + feedId).html(html);
    });
  }

  // mousedown/touchstart のバブリングを止め、jQuery UI sortable（モバイルでは
  // touch-punch）がガジェット並べ替えドラッグの開始としてこのタップを捕捉しない
  // ようにする（bookmark_gadget.js / todos.js と同じ手当て）。
  $(document).on('mousedown touchstart', SETTINGS_LINK_SELECTOR, function(e) {
    e.stopPropagation();
  });

  // document 委譲の stopPropagation だけでは touch-punch が先に touchstart を
  // 握って click を潰す。portal_gadget_sort.js のヘッダリンク対策と同様に
  // .gadgets へ直接 bind して stopImmediatePropagation する（#260731-u3v）。
  // ただしドラッグハンドル（.gadget-title-drag-handle）上の押下は並べ替えに
  // 委ねる — ここで止めると sortable にイベントが届かず、ガジェットを
  // ドラッグで移動できなくなる。ハンドル内のプロフィール／サイト名リンクは
  // portal_gadget_sort.js 側の HEADER_LINK_SELECTOR ガードが止めるので、
  // リンククリックとドラッグの両方が機能する。
  function bindHeaderSortGuards() {
    const $gadgets = $('.gadgets');
    if (!$gadgets.length) return;

    HEADER_WITH_EXTERNAL_LINK.forEach(({ header, settingsLink }) => {
      $gadgets
        .off('mousedown.gadgetSettingsHeader touchstart.gadgetSettingsHeader', header)
        .on('mousedown.gadgetSettingsHeader touchstart.gadgetSettingsHeader', header, function(e) {
          if ($(e.target).closest(settingsLink).length) return;
          if ($(e.target).closest('.gadget-title-drag-handle').length) return;
          e.stopImmediatePropagation();
        });
    });
  }

  bindHeaderSortGuards();

  // モバイルでヘッダ（アイコン/タイトル）をタップすると「設定」リンクの表示を切り替える。
  // タイトルが外部プロフィールへのリンクのため、初回タップでは遷移を
  // 抑止する（表示中にサイト名を再タップしたときだけリンク先へ進める）。
  HEADER_WITH_EXTERNAL_LINK.forEach(({ header, settingsLink }) => {
    $(document).on('click', header, function(e) {
      if (!MOBILE_MQ.matches) return;
      if ($(e.target).closest(settingsLink).length) return;

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
  });

  const ALL_HEADER_SELECTOR = HEADER_WITH_EXTERNAL_LINK.map(h => h.header).join(', ');

  $(document).on('touchstart', function(e) {
    if (!MOBILE_MQ.matches) return;
    if ($(e.target).closest(ALL_HEADER_SELECTOR).length) return;
    $(ALL_HEADER_SELECTOR).removeClass('title--gadget-actions-visible');
  });

  $(document).on('click', SETTINGS_LINK_SELECTOR, function(e) {
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
    const dialog = $form.closest('dialog')[0];
    if (dialog) dialog.close();

    if ($form.hasClass('gadget-settings-dialog__form')) {
      reloadGadget($form);
      return;
    }

    const feedId = $form.data('feedId');
    const feedUrl = $form.data('feedUrl');
    if (!feedId) return;
    applyFeedTitle($form, feedId);
    if (feedUrl) reloadFeedGadget(feedId, feedUrl);
  });

  $(document).on('ajax:error', '.feed-settings-dialog__form', function(e) {
    const xhr = (e.originalEvent || e).detail[2];
    alert((xhr && xhr.responseText) || 'エラーが発生しました');
  });
});
