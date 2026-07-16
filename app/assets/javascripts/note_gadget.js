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

    const DOUBLE_TAP_MS = 350;
    const TAP_MOVE_THRESHOLD_PX = 20;

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
      .on('ajax:success.noteGadget', '.note-item-delete-form', function() {
        const $gadget = $(this).closest('.note-gadget');
        const $item = $(this).closest('.note-item');
        $item.remove();
        if ($gadget.find('.note-list .note-item').length) return;
        const emptyLabel = $gadget.data('noteEmptyLabel');
        const $empty = $('<p>', { class: 'note-empty', text: emptyLabel });
        const $list = $gadget.find('.note-list');
        if ($list.length) {
          $list.replaceWith($empty);
        } else if (!$gadget.find('.note-empty').length) {
          $gadget.append($empty);
        }
      })
      .on('ajax:error.noteGadget', '.note-item-delete-form', function() {
        alert('エラーが発生しました');
      })
      .on('ajax:success.noteGadget', '.note-gadget-form', function(e) {
        const xhr = (e.originalEvent || e).detail[2];
        const $gadget = $(this).closest('.note-gadget');
        const $newItem = $(xhr.responseText);
        const $list = $gadget.find('.note-list');

        if ($list.length) {
          $list.prepend($newItem);
        } else {
          const $empty = $gadget.find('.note-empty');
          const $newList = $('<div>', { class: 'note-list' }).append($newItem);
          if ($empty.length) {
            $empty.replaceWith($newList);
          } else {
            $gadget.find('.note-gadget-composer').after($newList);
          }
        }

        const $textarea = $(this).find('textarea');
        $textarea.val('');
        $textarea.each(function() { this.style.height = ''; });
      })
      .on('ajax:error.noteGadget', '.note-gadget-form', function(e) {
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

    // Double-tap on mobile to enter edit mode (desktop already uses dblclick)
    $gadget
      .on('touchstart.noteGadget', '.note-item-display', function(e) {
        if (!MOBILE_MQ.matches) return;
        const $display = $(this);
        const t = e.originalEvent.touches[0];
        $display.data('tapStartX', t.clientX);
        $display.data('tapStartY', t.clientY);
      })
      .on('touchend.noteGadget', '.note-item-display', function(e) {
        if (!MOBILE_MQ.matches) return;
        const $display = $(this);
        const changed = (e.originalEvent.changedTouches && e.originalEvent.changedTouches[0]) || null;
        if (!changed) return;

        const startX = $display.data('tapStartX');
        const startY = $display.data('tapStartY');
        if (typeof startX === 'number' && typeof startY === 'number') {
          if (Math.abs(changed.clientX - startX) > TAP_MOVE_THRESHOLD_PX || Math.abs(changed.clientY - startY) > TAP_MOVE_THRESHOLD_PX) {
            return;
          }
        }

        const now = Date.now();
        const lastTapAt = $display.data('lastTapAt');
        if (lastTapAt && (now - lastTapAt) <= DOUBLE_TAP_MS) {
          $display.data('lastTapAt', null);
          e.preventDefault();
          showEditControls($display.closest('.note-item'));
          return;
        }
        $display.data('lastTapAt', now);
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
