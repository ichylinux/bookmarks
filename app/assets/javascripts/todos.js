if (typeof todos === "undefined") {
  var todos = {};
}

todos.init = function(selector) {
  $(selector).delegate('li', 'dblclick', function() {
    var that = this;
    $.get($(that).data('url'), {format: 'html'}, function(html) {
      $(that).html(html);
    });
  });

  $(selector).delegate('li span:first-child', 'click', function() {
    if (!$(this).parent().is('.todo_actions')) {
      $(this).toggleClass('selected');
      $(this).parent().toggleClass('selected');
    }
  });
};

todos.new_todo = function(trigger) {
  var ol = $(trigger).closest('ol');
  $.get(ol.data('url_for_new'), {format: 'html'}, function(html) {
    ol.find('.todo_actions').after('<li>' + html + '</li>');
  });
};

todos.create_todo = function(trigger) {
  var form = $(trigger).closest('form');
  if (form.find('input[type="text"]').val()) {
    $.post(form.attr('action'), form.serialize(), function(html) {
      form.closest('li').after(html).remove();
    });
  } else {
    form.closest('li').remove();
  }
};

todos.update_todo = function(trigger) {
  var form = $(trigger).closest('form');
  $.post(form.attr('action'), form.serialize(), function(html) {
    form.closest('li').replaceWith(html);
  });
};

todos.delete_todos = function(trigger) {
  var ol = $(trigger).closest('ol');

  var todo_id = [];
  ol.find('li.selected').each(function() {
    todo_id.push($(this).data('id'));
  });

  $.post(ol.data('url_for_delete'), {format: 'html', 'todo_id[]': todo_id}, function(html) {
    ol.find('li.selected').hide();
  });
};
