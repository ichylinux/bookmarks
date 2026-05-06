$(function() {
  'use strict';

  var MOBILE_MQ = window.matchMedia('(max-width: 767px)');
  var LONGPRESS_MS = 500;
  var MOVE_THRESHOLD_PX = 10;
  var TOUCH_MOUSE_GUARD_MS = 450;

  var $gadget = $('.note-gadget');
  if (!$gadget.length) return;

  var gadgetEl = $gadget[0];
  var labels = {
    update: gadgetEl.getAttribute('data-note-action-update-label') || 'Update',
    delete: gadgetEl.getAttribute('data-note-action-delete-label') || 'Delete'
  };

  var $backdrop = null;
  var $menu = null;
  var lastTouchInteraction = 0;

  function requestSubmitForm(form) {
    if (!form) return;
    if (typeof form.requestSubmit === 'function') {
      form.requestSubmit();
      return;
    }
    var btn = form.querySelector('input[type="submit"], button[type="submit"]');
    if (btn) btn.click();
  }

  function teardownMenu() {
    if ($backdrop) {
      $backdrop.remove();
      $backdrop = null;
    }
    if ($menu) {
      $menu.remove();
      $menu = null;
    }
    $(document).off('.noteGadgetMenu');
  }

  if (typeof MOBILE_MQ.addEventListener === 'function') {
    MOBILE_MQ.addEventListener('change', teardownMenu);
  }

  function openMenu(clientX, clientY, $item) {
    if (!MOBILE_MQ.matches) return;
    teardownMenu();

    var editForm = $item.find('.note-item-edit-form')[0];
    var deleteForm = $item.find('.note-item-delete-form')[0];
    if (!editForm || !deleteForm) return;

    $backdrop = $('<div class="note-item-context-backdrop" aria-hidden="true"></div>');
    $menu = $('<div class="note-item-context-menu" role="menu"></div>');
    var $btnUpdate = $('<button type="button" class="note-item-context-menu__item" role="menuitem"></button>')
      .text(labels.update);
    var $btnDelete = $('<button type="button" class="note-item-context-menu__item note-item-context-menu__item--danger" role="menuitem"></button>')
      .text(labels.delete);
    $menu.append($btnUpdate, $btnDelete);
    $('body').append($backdrop, $menu);

    function layoutMenu() {
      var pad = 8;
      var mw = $menu.outerWidth();
      var mh = $menu.outerHeight();
      var x = clientX - mw / 2;
      var y = clientY - mh / 2;
      x = Math.max(pad, Math.min(x, window.innerWidth - mw - pad));
      y = Math.max(pad, Math.min(y, window.innerHeight - mh - pad));
      $menu.css({ left: x + 'px', top: y + 'px' });
    }

    layoutMenu();
    window.requestAnimationFrame(layoutMenu);

    $btnUpdate.on('click', function() {
      teardownMenu();
      requestSubmitForm(editForm);
    });
    $btnDelete.on('click', function() {
      teardownMenu();
      requestSubmitForm(deleteForm);
    });

    $backdrop.on('click', teardownMenu);

    $(document).on('keydown.noteGadgetMenu', function(e) {
      if (e.key === 'Escape') teardownMenu();
    });
  }

  $('.note-item .note-item-edit-form textarea').each(function() {
    var $ta = $(this);
    var timer = null;
    var startX = 0;
    var startY = 0;
    var longPressTriggered = false;

    function clearTimer() {
      if (timer) {
        clearTimeout(timer);
        timer = null;
      }
    }

    function armTimer(clientX, clientY) {
      if (!MOBILE_MQ.matches) return;
      longPressTriggered = false;
      startX = clientX;
      startY = clientY;
      clearTimer();
      timer = setTimeout(function() {
        timer = null;
        longPressTriggered = true;
        openMenu(clientX, clientY, $ta.closest('.note-item'));
      }, LONGPRESS_MS);
    }

    function onMove(clientX, clientY) {
      if (!timer) return;
      if (Math.abs(clientX - startX) > MOVE_THRESHOLD_PX || Math.abs(clientY - startY) > MOVE_THRESHOLD_PX) {
        clearTimer();
      }
    }

    $ta.on('touchstart.noteGadgetLongpress', function(e) {
      lastTouchInteraction = Date.now();
      var t = e.originalEvent.touches[0];
      armTimer(t.clientX, t.clientY);
    });
    $ta.on('touchmove.noteGadgetLongpress', function(e) {
      var t = e.originalEvent.touches[0];
      onMove(t.clientX, t.clientY);
    });
    $ta.on('touchend.noteGadgetLongpress touchcancel.noteGadgetLongpress', function(e) {
      clearTimer();
      if (longPressTriggered) {
        e.preventDefault();
        longPressTriggered = false;
      }
    });

    $ta.on('mousedown.noteGadgetLongpress', function(e) {
      if (e.button !== 0) return;
      if (Date.now() - lastTouchInteraction < TOUCH_MOUSE_GUARD_MS) return;
      armTimer(e.clientX, e.clientY);
    });
    $ta.on('mousemove.noteGadgetLongpress', function(e) {
      onMove(e.clientX, e.clientY);
    });
    $ta.on('mouseup.noteGadgetLongpress', function(e) {
      clearTimer();
      if (longPressTriggered) {
        e.preventDefault();
        longPressTriggered = false;
      }
    });
    $ta.on('mouseleave.noteGadgetLongpress', function() {
      clearTimer();
    });

    $ta.on('contextmenu.noteGadgetLongpress', function(e) {
      if (MOBILE_MQ.matches) e.preventDefault();
    });
  });
});
