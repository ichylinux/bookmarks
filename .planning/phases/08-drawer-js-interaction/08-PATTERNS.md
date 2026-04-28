# Phase 8 — Pattern Map

**Phase:** 08 — Drawer JS Interaction  
**Output:** Closest analogs in-repo for executor `read_first` lists.

---

## Target file

| File | Role | Analog |
|------|------|--------|
| `app/assets/javascripts/menu.js` | Phase 8 implementation site | Current stub: `$(function(){ if (!modern) return; })`; Phase 3–4 scripts use `const`/`let`, jQuery `on`, no accidental globals — see `bookmarks.js` for structure reference |

---

## Regression anchor

| File | Pattern |
|------|---------|
| `app/views/common/_menu.html.erb` | `$('html').click` dismiss when `!$(e.target).closest('.email').length` — hamburger **must not** bubble to this |
| `app/views/layouts/application.html.erb` | `.hamburger-btn`, `.drawer`, `.drawer-overlay` markup |

---

## Test analog

| File | Pattern |
|------|---------|
| `test/controllers/welcome_controller/layout_structure_test.rb` | Integration tests for modern layout + `sign_in user` + `user.preference.update!(theme: 'modern')` |
| `test/application_system_test_case.rb` | `driven_by :selenium` — use **headless_chrome** in new system test file for CI-friendly runs |

---

## Excerpt: menu.js (current)

```javascript
$(function() {
  if (!$('body').hasClass('modern')) return;
  // Drawer interaction logic added in Phase 8.
});
```

Extend **inside** the guard only.
