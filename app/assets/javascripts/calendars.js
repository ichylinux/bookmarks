var calendars = {};

calendars.get_gadget = function(link) {
  var url = $(link).attr('href');
  $.get(url, {format: 'html'}, function(html) {
    $(link).closest('.gadget').find('table').replaceWith(html);
  });
};
