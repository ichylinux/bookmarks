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
  $(selector).on('dblclick', 'li:not(.todo_actions)', function() {
    todos.open_edit($(this));
  });

  $(selector).on('touchstart', 'li:not(.todo_actions)', function(e) {
    if (!MOBILE_MQ.matches) return;
    if ($(this).find('form.todo').length) return;
    const t = e.originalEvent.touches[0];
    $(this).data('tapStartX', t.clientX);
    $(this).data('tapStartY', t.clientY);
  });

  $(selector).on('touchend', 'li:not(.todo_actions)', function(e) {
    if (!MOBILE_MQ.matches) return;
    if ($(this).find('form.todo').length) return;
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
  });

  $(selector).on('click', 'li span:first-child', function() {
    if (!$(this).parent().is('.todo_actions')) {
      $(this).toggleClass('selected');
      $(this).parent().toggleClass('selected');
    }
  });

  $(selector).on('click', '.todo-highlight-btn:not(.todo-highlight-btn--form)', function(e) {
    e.preventDefault();
    e.stopPropagation();
    todos.toggle_highlight($(this));
  });
};

todos.toggle_highlight = function($btn) {
  const $li = $btn.closest('li');
  const inForm = $btn.hasClass('todo-highlight-btn--form');
  $.ajax({
    url: $btn.data('url'),
    type: 'PATCH',
    data: { authenticity_token: $('meta[name="csrf-token"]').attr('content') },
    success: function(html) {
      if (inForm) {
        const $updated = $(html);
        $li.toggleClass('highlighted', $updated.hasClass('highlighted'));
        const $updatedBtn = $updated.find('.todo-highlight-btn');
        $btn.attr('aria-pressed', $updatedBtn.attr('aria-pressed'));
        $btn.attr('aria-label', $updatedBtn.attr('aria-label'));
        $btn.text($updatedBtn.text());
      } else {
        $li.replaceWith(html);
      }
    }
  });
};

todos.new_todo = function(trigger) {
  const ol = $(trigger).closest('ol');
  const url = $(trigger).attr('href');

  $.get(url, {format: 'html'}, function(html) {
    ol.find('.todo_actions').after('<li>' + html + '</li>');
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
  const ol = $(trigger).closest('ol');
  const url = $(trigger).attr('href');

  const params = {};
  params.format = 'html';
  params.authenticity_token = $(trigger).closest('.todo_actions').data('authenticity_token');
  params.todo_id = [];
  ol.find('li.selected').each(function() {
    params.todo_id.push($(this).data('id'));
  });

  $.post(url, params, function () {
    ol.find('li.selected').hide();
  });
};
