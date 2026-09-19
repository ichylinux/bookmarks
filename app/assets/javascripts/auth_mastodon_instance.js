// Persist and restore the last entered Mastodon instance on sign-in / sign-up pages.
$(document).ready(() => {
  const input = document.getElementById('mastodon_instance');
  if (!input) return;

  const form = input.closest('form');
  const storageKey = form?.dataset.mastodonInstanceStorageKey;
  if (!storageKey) return;

  try {
    const saved = window.localStorage.getItem(storageKey);
    if (saved && !input.value) {
      input.value = saved;
    }
  } catch {
    // Ignore localStorage access errors in private mode or restricted browsers.
  }

  form.addEventListener('submit', () => {
    try {
      const value = input.value.trim();
      if (value) {
        window.localStorage.setItem(storageKey, value);
      }
    } catch {
      // Ignore localStorage access errors in private mode or restricted browsers.
    }
  });
});
