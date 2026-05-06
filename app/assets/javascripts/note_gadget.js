$(function() {
  'use strict';

  var MOBILE_MQ = window.matchMedia('(max-width: 767px)');
  var LONGPRESS_MS = 500;
  var MOVE_THRESHOLD_PX = 10;

  var $gadget = $('.note-gadget');
  if (!$gadget.length) return;

  function showEditControls($item) {
    if (!$item.length) return;
    if ($item.hasClass('note-item--editing')) return;
    var $editForm = $item.find('.note-item-edit-form');
    var $deleteForm = $item.find('.note-item-delete-form');
    $editForm.prop('hidden', false);
    $deleteForm.prop('hidden', false);
    $item.addClass('note-item--editing');
    var textarea = $editForm.find('textarea')[0];
    if (!textarea) return;
    textarea.focus();
    textarea.selectionStart = textarea.value.length;
    textarea.selectionEnd = textarea.value.length;
  }

  $('.note-item .note-item-display').each(function() {
    var $display = $(this);
    var $item = $display.closest('.note-item');
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

    $display.on('touchstart.noteGadgetLongpress', function(e) {
      if (!MOBILE_MQ.matches) return;
      var t = e.originalEvent.touches[0];
      armTimer(t.clientX, t.clientY);
    });
    $display.on('touchmove.noteGadgetLongpress', function(e) {
      if (!MOBILE_MQ.matches) return;
      var t = e.originalEvent.touches[0];
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
