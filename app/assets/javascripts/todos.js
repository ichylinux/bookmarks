// Sprockets bundle: share namespace for load order (no new globals).
window.todos = window.todos || {};
// NOTE: `todos` is a snapshot of the window.todos reference at parse time.
// window.todos remains the authoritative global; never reassign it in another
// file or the alias here will become stale.
const todos = window.todos;

const MOBILE_MQ = window.matchMedia('(max-width: 767px)');
const DOUBLE_TAP_MS = 350;
const TAP_MOVE_THRESHOLD_PX = 20;

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
    todos.open_edit($(this));
  });

  $(selector).on('touchstart', 'li', function(e) {
    if (!MOBILE_MQ.matches) return;
    if ($(this).find('form.todo').length) return;
    const t = e.originalEvent.touches[0];
    $(this).data('tapStartX', t.clientX);
    $(this).data('tapStartY', t.clientY);
  });

  $(selector).on('touchend', 'li', function(e) {
    if (!MOBILE_MQ.matches) return;
    if ($(this).find('form.todo').length) return;
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

  $(selector).on('click', 'li span:first-child', function() {
    $(this).toggleClass('selected');
    $(this).parent().toggleClass('selected');
    const ol = $(this).closest('ol');
    todos._updateCompleteGroup(ol);
  });

  $(selector).on('click', '.todo-highlight-btn', function(e) {
    e.preventDefault();
    e.stopPropagation();
    todos.toggle_highlight($(this));
  });
};

todos._updateCompleteGroup = function(ol) {
  const count = ol.find('li.selected').length;
  const $gadget = ol.closest('.gadget.todo');
  const $group = $gadget.find('.todo-gadget-complete-group');
  const $countEl = $group.find('.todo-gadget-selected-count');

  if (count > 0) {
    const template = $countEl.data('template'); // e.g. "%{count}件選択中"
    $countEl.text(template.replace('%{count}', count));
    $group.css('display', 'inline-flex');
  } else {
    $group.hide();
  }
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

todos.delete_todos = function(trigger) {
  const $trigger = $(trigger);
  const ol = $trigger.closest('ol').length
    ? $trigger.closest('ol')
    : $trigger.closest('.gadget.todo').find('ol').first();
  const url = $trigger.attr('href');

  const params = {};
  params.format = 'html';
  params.authenticity_token = $('meta[name="csrf-token"]').attr('content');
  params.todo_id = [];
  ol.find('li.selected').each(function() {
    params.todo_id.push($(this).data('id'));
  });
  if (params.todo_id.length === 0) return;
  $.post(url, params, function () {
    ol.find('li.selected').hide();
    todos._updateCompleteGroup(ol);
  });
};
