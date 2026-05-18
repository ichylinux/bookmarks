---
phase: 87-js-click-handler
plan: "01"
subsystem: javascript
tags: [visited-links, js, iife, click-handler, contract-test]
dependency_graph:
  requires: []
  provides: [visited_links.js, VisitedLinksJsContractTest]
  affects: [app/assets/javascripts/application.js via require_tree .]
tech_stack:
  added: []
  patterns: [jQuery delegated click handler, pure IIFE, fire-and-forget $.post]
key_files:
  created:
    - app/assets/javascripts/visited_links.js
    - test/assets/visited_links_js_contract_test.rb
  modified: []
decisions:
  - Pure IIFE with no window export — handler is self-contained fire-and-forget
  - function() callback (not arrow) so `this` resolves to clicked DOM element
  - addClass before $.post for optimistic update
  - var url (not const/let) — consistent with ESLint config (no no-var rule)
metrics:
  duration: "~5 minutes"
  completed: "2026-05-18"
  tasks_completed: 2
  tasks_total: 2
requirements-completed:
  - JS-01
  - JS-02
---

# Phase 87 Plan 01: visited_links.js IIFE Click Handler Summary

**One-liner:** jQuery delegated click handler as pure IIFE — strips fragment, optimistically marks `.link--visited`, fire-and-forget POST to `/visited_links`.

## What Was Built

### `app/assets/javascripts/visited_links.js`
A 7-line pure IIFE that registers a namespaced delegated click handler:

```js
(function () {
  $(document).on('click.visitedLinks', '.gadget ol li a[href]', function () {
    var url = this.href.replace(/#.*$/, '');
    $(this).addClass('link--visited');
    $.post('/visited_links', { url: url });
  });
})();
```

Key properties:
- Auto-included by Sprockets `require_tree .` — no manual require needed
- `.visitedLinks` namespace allows clean teardown without affecting other handlers
- Delegated on `document` — fires on AJAX-injected gadget content
- No `e.preventDefault()` — link navigates normally
- No `.fail()` — visited state is best-effort (next reload corrects from DB)
- CSRF token injected automatically by `rails-ujs` `$.ajaxPrefilter`

### `test/assets/visited_links_js_contract_test.rb`
`VisitedLinksJsContractTest` with 7 passing assertions covering:
1. IIFE wrapper structure (not DOMReady)
2. Namespaced delegated handler signature
3. `addClass` precedes `$.post` (optimistic ordering enforced by String#index)
4. Fragment strip regex matches Ruby `normalize_url`
5. No `preventDefault` call
6. No `.fail(` chained handler
7. No `window.*=` namespace export

## Verification Results

| Check | Result |
|-------|--------|
| `yarn run lint` | ✅ 0 errors, 0 warnings |
| `bin/rails test test/assets/visited_links_js_contract_test.rb` | ✅ 7 tests, 0 failures |
| `bin/rails test` (full suite) | ✅ 455 runs, 0 failures |

## Commits

| Hash | Message |
|------|---------|
| 9c47388 | feat(87-01): add visited_links.js IIFE click handler |
| f371df1 | feat(87-01): add contract test for visited_links.js |

## Deviations from Plan

None — plan executed exactly as written.

## Self-Check: PASSED
- `app/assets/javascripts/visited_links.js` — exists ✅
- `test/assets/visited_links_js_contract_test.rb` — exists ✅
- Commit 9c47388 — exists ✅
- Commit f371df1 — exists ✅
