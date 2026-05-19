$(function() {
  'use strict';

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
    if (window.matchMedia('(max-width: 767px)').matches) {
      autoResizeTextarea(textarea);
      $(textarea).off('input.noteGadgetResize').on('input.noteGadgetResize', function() { autoResizeTextarea(this); });
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

  function initNoteGadget() {
    const $gadget = $('.note-gadget');
    if (!$gadget.length) return;

    // One-time setup for static elements
    $gadget.find('.note-submit-shortcut').each(function() {
      const macLabel = $(this).data('shortcutMac');
      if (macLabel && /Mac|iPhone|iPad|iPod/.test(navigator.platform)) {
        $(this).text(macLabel);
      }
    });

    const MOBILE_MQ = window.matchMedia('(max-width: 767px)');
    const LONGPRESS_MS = 500;
    const MOVE_THRESHOLD_PX = 10;

    // Use event delegation on the gadget container for all dynamic interactions
    $gadget.off('.noteGadget')
      .on('ajax:success.noteGadget', '.note-item-edit-form', function(e) {
        const xhr = (e.originalEvent || e).detail[2];
        $(this).closest('.note-item').replaceWith(xhr.responseText);
        // NO recursive initNoteGadget() call here!
      })
      .on('ajax:error.noteGadget', '.note-item-edit-form', function(e) {
        const xhr = (e.originalEvent || e).detail[2];
        alert((xhr && xhr.responseText) || 'エラーが発生しました');
      })
      .on('keydown.noteGadget', 'textarea', function(e) {
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
      })
      .on('dblclick.noteGadget', '.note-item-display', function() {
        if (MOBILE_MQ.matches) return;
        showEditControls($(this).closest('.note-item'));
      })
      .on('click.noteGadget', '.note-item-cancel-button', function() {
        hideEditControls($(this).closest('.note-item'));
      });

    // Longpress handling using delegation
    $gadget
      .on('touchstart.noteGadget', '.note-item-display', function(e) {
        if (!MOBILE_MQ.matches) return;
        const $display = $(this);
        const t = e.originalEvent.touches[0];
        const timer = setTimeout(function() {
          $display.data('longPressTimer', null);
          $display.data('longPressTriggered', true);
          showEditControls($display.closest('.note-item'));
        }, LONGPRESS_MS);
        $display.data('longPressTimer', timer);
        $display.data('longPressStartX', t.clientX);
        $display.data('longPressStartY', t.clientY);
        $display.data('longPressTriggered', false);
      })
      .on('touchmove.noteGadget', '.note-item-display', function(e) {
        if (!MOBILE_MQ.matches) return;
        const $display = $(this);
        const timer = $display.data('longPressTimer');
        if (!timer) return;
        const t = e.originalEvent.touches[0];
        const startX = $display.data('longPressStartX');
        const startY = $display.data('longPressStartY');
        if (Math.abs(t.clientX - startX) > MOVE_THRESHOLD_PX || Math.abs(t.clientY - startY) > MOVE_THRESHOLD_PX) {
          clearTimeout(timer);
          $display.data('longPressTimer', null);
        }
      })
      .on('touchend.noteGadget touchcancel.noteGadget', '.note-item-display', function(e) {
        const $display = $(this);
        const timer = $display.data('longPressTimer');
        if (timer) {
          clearTimeout(timer);
          $display.data('longPressTimer', null);
        }
        if ($display.data('longPressTriggered')) {
          e.preventDefault();
          $display.data('longPressTriggered', false);
        }
      })
      .on('contextmenu.noteGadget', '.note-item-display', function(e) {
        if (MOBILE_MQ.matches) {
          e.preventDefault();
        }
      });

    // Tap-to-show edit time tooltip on touch devices
    if (window.matchMedia('(hover: none)').matches) {
      $gadget.on('click.noteGadget', '.note-edited-badge', function(e) {
        e.stopPropagation();
        var $badge = $(this);
        var wasActive = $badge.hasClass('tooltip-active');
        $('.note-edited-badge.tooltip-active').removeClass('tooltip-active');
        if (!wasActive) $badge.addClass('tooltip-active');
      });
      $(document).off('.noteEditedBadgeDismiss').on('click.noteEditedBadgeDismiss', function() {
        $('.note-edited-badge.tooltip-active').removeClass('tooltip-active');
      });
    }
  }

  // Initialize on DOM ready
  initNoteGadget();

  // Re-initialize after AJAX injection of note gadget
  $(document).on('noteGadgetLoaded', function() {
    initNoteGadget();
  });

});
