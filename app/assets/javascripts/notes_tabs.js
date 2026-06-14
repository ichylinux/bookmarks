$(function () {
  // Derive theme hidden-class and home panel selector once.
  const isSimple = $('body').hasClass('simple');
  const hiddenClass = isSimple ? 'simple-tab-panel--hidden' : 'welcome-tab-panel--hidden';
  const $homePanel = isSimple ? $('#simple-home-panel') : $('#welcome-home-panel');
  const $notesPanel = $('#notes-tab-panel');

  let notesLoaded = false;

  // window.notePane: theme-agnostic shared note-pane reveal API.
  // Consumed by portal_mobile_tabs.js (swipe) and dormant tab buttons.
  window.notePane = {
    available: function () {
      return $notesPanel.length > 0;
    },
    isVisible: function () {
      return $notesPanel.length > 0 && !$notesPanel.hasClass(hiddenClass);
    },
    show: function () {
      if (!$notesPanel.length) return;
      $homePanel.addClass(hiddenClass);
      $notesPanel.removeClass(hiddenClass);
      // Sync header note button (present in drawer themes)
      $('.head-note-btn').addClass('head-note-btn--active');
      // Sync dormant simple-tab buttons
      $('button.simple-tab[data-simple-tab]').removeClass('simple-tab--active');
      $('button.simple-tab[data-simple-tab="notes"]').addClass('simple-tab--active');
      // Lazy-load gadget once; reset flag on failure so a later attempt can retry
      if (!notesLoaded) {
        notesLoaded = true;
        $.get('/notes/gadget', function (html) {
          $notesPanel.html(html);
          $(document).trigger('noteGadgetLoaded');
        }).fail(function (xhr) {
          console.warn('note gadget load failed', xhr.status);
          notesLoaded = false;
        });
      }
    },
    hide: function () {
      if (!$notesPanel.length) return;
      $homePanel.removeClass(hiddenClass);
      $notesPanel.addClass(hiddenClass);
      // Sync header note button
      $('.head-note-btn').removeClass('head-note-btn--active');
      // Sync dormant simple-tab buttons
      $('button.simple-tab[data-simple-tab]').removeClass('simple-tab--active');
      $('button.simple-tab[data-simple-tab="home"]').addClass('simple-tab--active');
    },
  };

  // Early-return when note panel absent (use_note disabled for this user/page).
  // window.notePane is defined above so portal_mobile_tabs.js can call notePane.available().
  if (!window.notePane.available()) return;

  // Initialize panel visibility from query string for all themes (not just simple).
  const initFromQuery = function () {
    const params = new URLSearchParams(window.location.search);
    const tab = params.get('tab');
    if (tab === 'notes') {
      window.notePane.show();
    }
    // else: home panel is already shown by server-rendered markup
  };

  initFromQuery();

  // Dormant simple-tab button bindings (buttons not currently rendered; future-proof).
  $('button.simple-tab[data-simple-tab]').on('click', function () {
    const target = $(this).attr('data-simple-tab');
    if (target === 'notes') {
      window.notePane.show();
    } else if (target === 'home') {
      window.notePane.hide();
    }
  });
});
