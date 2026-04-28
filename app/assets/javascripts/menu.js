$(function() {
  if (!$('body').hasClass('modern')) return;

  const $body = $('body');

  const closeDrawer = function() {
    $body.removeClass('drawer-open');
  };

  const toggleDrawer = function() {
    $body.toggleClass('drawer-open');
  };

  $('.hamburger-btn').on('click', function(e) {
    e.stopPropagation();
    toggleDrawer();
  });

  $('.drawer-overlay').on('click', function() {
    closeDrawer();
  });

  $(document).on('keydown.phase8Drawer', function(e) {
    if (e.key === 'Escape' && $body.hasClass('drawer-open')) {
      closeDrawer();
    }
  });

  $('.drawer nav').on('click', 'a', function() {
    closeDrawer();
  });
});
