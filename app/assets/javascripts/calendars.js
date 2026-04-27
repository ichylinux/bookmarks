// Sprockets bundle: share namespace for load order (no new globals).
window.calendars = window.calendars || {};
const calendars = window.calendars;

calendars.get_gadget = function(link) {
  const url = $(link).attr('href');
  $.get(url, {format: 'html'}, (html) => {
    $(link).closest('.gadget').find('table').replaceWith(html);
  });
};
