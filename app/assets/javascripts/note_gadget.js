$(function() {
  'use strict';

  const MOBILE_MQ = window.matchMedia('(max-width: 767px)');
  const LONGPRESS_MS = 500;
  const MOVE_THRESHOLD_PX = 10;

  const $gadget = $('.note-gadget');
  if (!$gadget.length) return;

  function showEditControls($item) {
    if (!$item.length) return;
    if ($item.hasClass('note-item--editing')) return;
    const $editForm = $item.find('.note-item-edit-form');
    const $deleteForm = $item.find('.note-item-delete-form');
    const $cancelButton = $item.find('.note-item-cancel-button');
    $editForm.prop('hidden', false);
    $deleteForm.prop('hidden', false);
    $cancelButton.prop('hidden', false);
    $item.addClass('note-item--editing');
    const textarea = $editForm.find('textarea')[0];
    if (!textarea) return;
    textarea.focus();
    textarea.selectionStart = textarea.value.length;
    textarea.selectionEnd = textarea.value.length;
  }

  function hideEditControls($item) {
    if (!$item.length) return;
    if (!$item.hasClass('note-item--editing')) return;
    $item.find('.note-item-edit-form').prop('hidden', true);
    $item.find('.note-item-delete-form').prop('hidden', true);
    $item.find('.note-item-cancel-button').prop('hidden', true);
    $item.removeClass('note-item--editing');
    $item.find('.note-item-display').focus();
  }

  $('.note-item .note-item-display').each(function() {
    const $display = $(this);
    const $item = $display.closest('.note-item');
    let timer = null;
    let startX = 0;
    let startY = 0;
    let longPressTriggered = false;

    function clearTimer() {
      if (timer) {
        clearTimeout(timer);
        timer = null;
      }
    }

    function armTimer(clientX, clientY) {
      longPressTriggered = false;
      startX = clientX;
      startY = clientY;
      clearTimer();
      timer = setTimeout(function() {
        timer = null;
        longPressTriggered = true;
        showEditControls($item);
      }, LONGPRESS_MS);
    }

    function onMove(clientX, clientY) {
      if (!timer) return;
      if (Math.abs(clientX - startX) > MOVE_THRESHOLD_PX || Math.abs(clientY - startY) > MOVE_THRESHOLD_PX) {
        clearTimer();
      }
    }

    $display.on('dblclick.noteGadgetEdit', function() {
      if (MOBILE_MQ.matches) return;
      showEditControls($item);
    });

    $item.on('click.noteGadgetEditCancel', '.note-item-cancel-button', function() {
      hideEditControls($item);
    });

    $display.on('touchstart.noteGadgetLongpress', function(e) {
      if (!MOBILE_MQ.matches) return;
      const t = e.originalEvent.touches[0];
      armTimer(t.clientX, t.clientY);
    });
    $display.on('touchmove.noteGadgetLongpress', function(e) {
      if (!MOBILE_MQ.matches) return;
      const t = e.originalEvent.touches[0];
      onMove(t.clientX, t.clientY);
    });
    $display.on('touchend.noteGadgetLongpress touchcancel.noteGadgetLongpress', function(e) {
      clearTimer();
      if (longPressTriggered) {
        e.preventDefault();
        longPressTriggered = false;
      }
    });

    $display.on('contextmenu.noteGadgetLongpress', function(e) {
      if (MOBILE_MQ.matches) {
        e.preventDefault();
      }
    });
  });

});
