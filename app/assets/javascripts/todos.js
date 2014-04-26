if (typeof todos === "undefined") {
  var todos = {};
}

todos.update_todo = function(trigger) {
  var form = $(trigger).closest('form');
  $.post(form.attr('action'), form.serialize(), function(html) {
    form.closest('li').replaceWith(html);
  });
};
