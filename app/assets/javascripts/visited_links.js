(function () {
  const STORAGE_KEY = 'bookmarksPendingVisitedLinks';
  const POST_URL = '/visited_links';
  const SESSION_META_SELECTOR = 'meta[name="bookmarks-session-active"]';

  function sessionActiveOnPage() {
    return document.querySelector(SESSION_META_SELECTOR) !== null;
  }

  function markSessionExpired() {
    const meta = document.querySelector(SESSION_META_SELECTOR);
    if (meta) {
      meta.remove();
    }
  }

  function readQueue() {
    try {
      const raw = window.localStorage.getItem(STORAGE_KEY);
      if (!raw) return [];
      const parsed = JSON.parse(raw);
      return Array.isArray(parsed) ? parsed : [];
    } catch {
      return [];
    }
  }

  function writeQueue(items) {
    try {
      if (items.length === 0) {
        window.localStorage.removeItem(STORAGE_KEY);
      } else {
        window.localStorage.setItem(STORAGE_KEY, JSON.stringify(items));
      }
    } catch {
      // Ignore localStorage access errors in private mode or restricted browsers.
    }
  }

  function removeFromQueue(url) {
    writeQueue(readQueue().filter(function (item) {
      return item.url !== url;
    }));
  }

  function enqueue(payload) {
    const queue = readQueue();
    const existing = queue.findIndex(function (item) {
      return item.url === payload.url;
    });
    if (existing >= 0) {
      queue[existing] = Object.assign({}, queue[existing], payload);
    } else {
      queue.push(payload);
    }
    writeQueue(queue);
  }

  function postVisitedLink(payload) {
    if (!sessionActiveOnPage()) {
      enqueue(payload);
      return;
    }

    return $.ajax({
      url: POST_URL,
      method: 'POST',
      data: payload
    }).done(function (_data, _textStatus, xhr) {
      if (xhr && xhr.status === 204) {
        removeFromQueue(payload.url);
      }
    }).fail(function () {
      markSessionExpired();
      enqueue(payload);
    });
  }

  function buildPayload(url, title, gadgetId) {
    if (gadgetId.indexOf('feed_') === 0) {
      return { url: url, title: title, source: 'feed', gadget_id: gadgetId };
    }
    if (gadgetId.indexOf('x_account_') === 0) {
      return { url: url, title: title, source: 'x', gadget_id: gadgetId };
    }
    if (gadgetId.indexOf('mastodon_account_') === 0) {
      return { url: url, title: title, source: 'mastodon', gadget_id: gadgetId };
    }
    return { url: url };
  }

  function flushPending() {
    if (!sessionActiveOnPage()) return;
    readQueue().forEach(function (payload) {
      if (!sessionActiveOnPage()) return;
      postVisitedLink(payload);
    });
  }

  $(document).on('click.visitedLinks', '.gadget:not(#bookmark_gadget):not(#todo) ol li a[href]', function () {
    const url = this.href.replace(/#.*$/, '');
    $(this).addClass('link--visited');
    const gadget = $(this).closest('.gadget');
    const gadgetId = gadget.attr('id') || '';
    const title = $(this).text().trim();
    postVisitedLink(buildPayload(url, title, gadgetId));
  });

  flushPending();
})();