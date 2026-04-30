---
quick_id: 260430-pph
slug: modenize-javascript-in-notes-tabs-js
status: planned
created: 2026-04-30
---

# Quick Task 260430-pph: modenize JavaScript in notes_tabs.js

## Goal

Modernize `app/assets/javascripts/notes_tabs.js` while preserving the simple-theme tab behavior.

## Tasks

1. Update local declarations in `notes_tabs.js` from `var` to `const`.
2. Use a template literal for the active tab selector and an arrow callback where `this` binding is not required.
3. Run the JavaScript lint check for `app/assets/javascripts/**/*.js`.

## Acceptance Criteria

- The script still exits early outside the simple theme.
- `?tab=notes` activates the notes panel; other query values activate the home panel.
- Clicking either simple tab still switches panels without a page reload.
- ESLint passes.
