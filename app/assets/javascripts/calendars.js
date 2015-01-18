var calendars = {};

calendars.get_gadget = function(link) {
  var url = $(link).attr('href');
  $.get(url, {format: 'html'}, function(html) {
    $(link).closest('.gadget').find('table').replaceWith(html);
  });
};

calendars.init_form = function() {
  $('.new_calendar, .edit_calendar').each(function() {
    var show_weather = $(this).find('input[name*="show_weather"]');
    show_weather.change(calendars.update_prefecture);
  });
};
