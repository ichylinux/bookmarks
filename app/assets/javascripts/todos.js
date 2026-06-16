// Sprockets bundle: share namespace for load order (no new globals).
window.todos = window.todos || {};
// NOTE: `todos` is a snapshot of the window.todos reference at parse time.
// window.todos remains the authoritative global; never reassign it in another
// file or the alias here will become stale.
const todos = window.todos;

const MOBILE_MQ = window.matchMedia('(max-width: 767px)');
const DOUBLE_TAP_MS = 350;
const TAP_MOVE_THRESHOLD_PX = 20;
const COMPLETE_FADE_MS = 300;
const UNDO_TOAST_MS = 3000;

todos.open_edit = function($li) {
  const $textInput = $li.find('input[type="text"]').first();

  if ($textInput.length) {
    $textInput.focus();
    setTimeout(function() {
      $textInput.select();
    }, 0);
  } else {
    $.get($li.data('url'), {format: 'html'}, function(html) {
      $li.html(html);
    });
  }
};

todos.init = function(selector) {
  $(selector).on('mousedown', '.todo-gadget-new-link', function(e) {
    e.stopPropagation();
  });

  $(selector).on('dblclick', 'li', function() {
    if ($(this).find('form.todo').length) return;
    todos.open_edit($(this));
  });

  $(selector).on('touchstart', 'li', function(e) {
    if (!MOBILE_MQ.matches) return;
    if ($(this).find('form.todo').length) return;
    if ($(e.target).closest('span:first-child').length) return;
    const t = e.originalEvent.touches[0];
    $(this).data('tapStartX', t.clientX);
    $(this).data('tapStartY', t.clientY);
  });

  $(selector).on('touchend', 'li', function(e) {
    if (!MOBILE_MQ.matches) return;
    if ($(this).find('form.todo').length) return;
    if ($(e.target).closest('span:first-child').length) return;
    if ($(e.target).closest('.todo-highlight-btn').length) return;
    const $li = $(this);
    const changed = (e.originalEvent.changedTouches && e.originalEvent.changedTouches[0]) || null;
    if (!changed) return;

    const startX = $li.data('tapStartX');
    const startY = $li.data('tapStartY');
    if (typeof startX === 'number' && typeof startY === 'number') {
      if (Math.abs(changed.clientX - startX) > TAP_MOVE_THRESHOLD_PX ||
          Math.abs(changed.clientY - startY) > TAP_MOVE_THRESHOLD_PX) {
        return;
      }
    }

    const now = Date.now();
    const lastTapAt = $li.data('lastTapAt');
    if (lastTapAt && (now - lastTapAt) <= DOUBLE_TAP_MS) {
      $li.data('lastTapAt', null);
      e.preventDefault();
      todos.open_edit($li);
      return;
    }
    $li.data('lastTapAt', now);
    $li.siblings().removeClass('todo-highlight-visible');
    $li.toggleClass('todo-highlight-visible');
  });

  $(document).on('touchstart', function(e) {
    if (!MOBILE_MQ.matches) return;
    if (!$(e.target).closest('.todo li').length) {
      $('.todo li.todo-highlight-visible').removeClass('todo-highlight-visible');
    }
  });

  $(selector).on('click', 'li span:first-child', function(e) {
    const $li = $(this).closest('li');
    if ($li.find('form.todo').length || $li.hasClass('todo-completing')) return;
    e.preventDefault();
    e.stopPropagation();
    todos.complete_todo($li);
  });

  $(selector).on('click', '.todo-highlight-btn', function(e) {
    e.preventDefault();
    e.stopPropagation();
    todos.toggle_highlight($(this));
  });
};

todos.toggle_highlight = function($btn) {
  const $li = $btn.closest('li');
  $.ajax({
    url: $btn.data('url'),
    type: 'PATCH',
    data: { authenticity_token: $('meta[name="csrf-token"]').attr('content') },
    success: function(html) {
      $li.replaceWith(html);
    }
  });
};

todos.new_todo = function(trigger) {
  const $trigger = $(trigger);
  const ol = $trigger.closest('ol').length
    ? $trigger.closest('ol')
    : $trigger.closest('.gadget.todo').find('ol').first();
  const url = $trigger.attr('href');

  $.get(url, {format: 'html'}, function(html) {
    ol.prepend('<li>' + html + '</li>');
  });
};

todos.create_todo = function(trigger) {
  const form = $(trigger).closest('form');
  if (form.find('input[type="text"]').val()) {
    $.post(form.attr('action'), form.serialize(), function(html) {
      form.closest('li').after(html).remove();
    });
  } else {
    form.closest('li').remove();
  }
};

todos.update_todo = function(trigger) {
  const form = $(trigger).closest('form');
  $.post(form.attr('action'), form.serialize(), function(html) {
    form.closest('li').replaceWith(html);
  });
};

todos._clearUndoToast = function() {
  if (todos._undoTimer) {
    clearTimeout(todos._undoTimer);
    todos._undoTimer = null;
  }
  if (todos._undoToast) {
    todos._undoToast.remove();
    todos._undoToast = null;
  }
};

todos._showUndoToast = function($gadget, payload) {
  todos._clearUndoToast();

  const $ol = $gadget.find('ol').first();
  const template = $ol.data('toast-completed') || 'Completed “%{title}”';
  const undoLabel = $ol.data('toast-undo') || 'Undo';
  const message = template.replace('%{title}', payload.title);

  const $toast = $(
    '<div class="todo-undo-toast" role="status">' +
      '<span class="todo-undo-toast__message"></span>' +
      '<button type="button" class="todo-undo-toast__undo"></button>' +
    '</div>'
  );
  $toast.find('.todo-undo-toast__message').text(message);
  $toast.find('.todo-undo-toast__undo').text(undoLabel);

  $gadget.find('> div').append($toast);
  todos._undoToast = $toast;
  todos._undoPayload = payload;

  $toast.find('.todo-undo-toast__undo').on('click', function() {
    todos.undo_complete($gadget);
  });

  todos._undoTimer = setTimeout(function() {
    todos._clearUndoToast();
    todos._undoPayload = null;
  }, UNDO_TOAST_MS);
};

todos.complete_todo = function($li) {
  if ($li.hasClass('todo-completing')) return;

  const $ol = $li.closest('ol');
  const $gadget = $ol.closest('.gadget.todo');
  const todoId = $li.data('id');
  const title = $.trim($li.find('.todo-title').text());
  const $insertBefore = $li.next();

  todos._clearUndoToast();

  $li.addClass('todo-completing todo-completed');

  $.post($ol.data('complete-url'), {
    format: 'html',
    authenticity_token: $ol.data('authenticity-token'),
    todo_id: [todoId]
  });

  setTimeout(function() {
    $li.remove();
  }, COMPLETE_FADE_MS);

  todos._showUndoToast($gadget, {
    todoId: todoId,
    title: title,
    $insertBefore: $insertBefore
  });
};

todos.undo_complete = function($gadget) {
  const payload = todos._undoPayload;
  if (!payload) return;

  const $ol = $gadget.find('ol').first();
  todos._clearUndoToast();

  $.post($ol.data('undo-url'), {
    format: 'html',
    authenticity_token: $ol.data('authenticity-token'),
    todo_id: [payload.todoId]
  }, function(html) {
    const $item = $(html);
    if (payload.$insertBefore && payload.$insertBefore.length) {
      payload.$insertBefore.before($item);
    } else {
      $ol.append($item);
    }
    todos._undoPayload = null;
  });
};
