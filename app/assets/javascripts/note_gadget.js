$(function() {
  'use strict';

  function initNoteGadget() {
    const MOBILE_MQ = window.matchMedia('(max-width: 767px)');
    const LONGPRESS_MS = 500;
    const MOVE_THRESHOLD_PX = 10;

    const $gadget = $('.note-gadget');
    if (!$gadget.length) return;

    $gadget.find('.note-submit-shortcut').each(function() {
      const macLabel = $(this).data('shortcutMac');
      if (macLabel && /Mac|iPhone|iPad|iPod/.test(navigator.platform)) {
        $(this).text(macLabel);
      }
    });

    function autoResizeTextarea(el) {
      el.style.height = 'auto';
      el.style.height = el.scrollHeight + 'px';
    }

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
      if (MOBILE_MQ.matches) {
        autoResizeTextarea(textarea);
        $(textarea).on('input.noteGadgetResize', function() { autoResizeTextarea(this); });
      }
    }

    function hideEditControls($item) {
      if (!$item.length) return;
      if (!$item.hasClass('note-item--editing')) return;
      const $ta = $item.find('.note-item-edit-form textarea');
      $ta.off('input.noteGadgetResize');
      $ta.each(function() { this.style.height = ''; });
      $item.find('.note-item-edit-form').prop('hidden', true);
      $item.find('.note-item-delete-form').prop('hidden', true);
      $item.find('.note-item-cancel-button').prop('hidden', true);
      $item.removeClass('note-item--editing');
      $item.find('.note-item-display').focus();
    }

    // Remove any previously attached delegated handlers to avoid duplicates on re-init
    $gadget.off('.noteGadgetSave').on('keydown.noteGadgetSave', 'textarea', function(e) {
      if (!(e.ctrlKey || e.metaKey) || e.key.toLowerCase() !== 's') return;
      e.preventDefault();
      const form = $(this).closest('form')[0];
      if (!form) return;
      const submit = form.querySelector('input[type="submit"], button[type="submit"]');
      if (submit) {
        submit.click();
      } else {
        form.submit();
      }
    });

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

      // Remove previous handlers before re-binding (re-init safety)
      $display.off('.noteGadgetEdit .noteGadgetLongpress');
      $item.off('.noteGadgetEditCancel');

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
  }

  // Initialize on DOM ready (SSR path — modern/classic without AJAX, or future use)
  initNoteGadget();

  // Re-initialize after AJAX injection of note gadget (AJAX path — Phase 79)
  $(document).on('noteGadgetLoaded', function() {
    initNoteGadget();
  });

});
