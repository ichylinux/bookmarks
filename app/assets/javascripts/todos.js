// Sprockets bundle: share namespace for load order (no new globals).
window.todos = window.todos || {};
const todos = window.todos;

todos.init = function(selector) {
  $(selector).on('dblclick', 'li', function() {
    const $li = $(this);
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
  });

  $(selector).on('click', 'li span:first-child', function() {
    if (!$(this).parent().is('.todo_actions')) {
      $(this).toggleClass('selected');
      $(this).parent().toggleClass('selected');
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
