$(function() {
  if (!$('body').hasClass('simple')) return;

  var $homePanel = $('#simple-home-panel');
  var $notesPanel = $('#notes-tab-panel');
  var $tabs = $('button.simple-tab[data-simple-tab]');

  function activateTab(which) {
    var isNotes = which === 'notes';
    $tabs.removeClass('simple-tab--active');
    $tabs.filter('[data-simple-tab="' + which + '"]').addClass('simple-tab--active');

    if (isNotes) {
      $homePanel.addClass('simple-tab-panel--hidden');
      $notesPanel.removeClass('simple-tab-panel--hidden');
    } else {
      $homePanel.removeClass('simple-tab-panel--hidden');
      $notesPanel.addClass('simple-tab-panel--hidden');
    }
  }

  function initFromQuery() {
    var params = new URLSearchParams(window.location.search);
    var tab = params.get('tab');
    if (tab === 'notes') {
      activateTab('notes');
    } else {
      activateTab('home');
    }
  }

  initFromQuery();

  $tabs.on('click', function() {
    var target = $(this).attr('data-simple-tab');
    if (target === 'home' || target === 'notes') {
      activateTab(target);
    }
  });
});
