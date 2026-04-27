// Sprockets bundle: share namespace for load order (no new globals).
window.calendars = window.calendars || {};
// NOTE: `calendars` is a snapshot of the window.calendars reference at parse
// time. window.calendars remains the authoritative global; never reassign it
// in another file or the alias here will become stale.
const calendars = window.calendars;

calendars.get_gadget = function(link) {
  const url = $(link).attr('href');
  $.get(url, {format: 'html'}, (html) => {
    $(link).closest('.gadget').find('table').replaceWith(html);
  });
};
