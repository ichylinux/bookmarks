$(function() {
  if (!$('body').hasClass('simple')) return;

  const $homePanel = $('#simple-home-panel');
  const $notesPanel = $('#notes-tab-panel');
  const $tabs = $('button.simple-tab[data-simple-tab]');

  const activateTab = (which) => {
    const isNotes = which === 'notes';
    $tabs.removeClass('simple-tab--active');
    $tabs.filter(`[data-simple-tab="${which}"]`).addClass('simple-tab--active');

    if (isNotes) {
      $homePanel.addClass('simple-tab-panel--hidden');
      $notesPanel.removeClass('simple-tab-panel--hidden');
    } else {
      $homePanel.removeClass('simple-tab-panel--hidden');
      $notesPanel.addClass('simple-tab-panel--hidden');
    }
  };

  const initFromQuery = () => {
    const params = new URLSearchParams(window.location.search);
    const tab = params.get('tab');
    if (tab === 'notes') {
      activateTab('notes');
    } else {
      activateTab('home');
    }
  };

  initFromQuery();

  $tabs.on('click', function() {
    const target = $(this).attr('data-simple-tab');
    if (target === 'home' || target === 'notes') {
      activateTab(target);
    }
  });
});
