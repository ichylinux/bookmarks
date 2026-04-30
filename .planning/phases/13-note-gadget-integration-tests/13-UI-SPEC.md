---
phase: 13
phase_name: Note Gadget + Integration Tests
status: approved
date: 2026-04-30
---

# Phase 13 UI Design Contract

## 1. Layout and hierarchy

### Simple-theme Note tab

- Keep the existing `#notes-tab-panel` mount point in `app/views/welcome/index.html.erb`. The Phase 13 implementation must replace the current placeholder content inside that panel; it must not rename, remove, or duplicate the panel.
- Render the note gadget through a dedicated partial inside `#notes-tab-panel`, with one top-level section:

```erb
<section class="note-gadget">
```

- The `.note-gadget` section must contain, in this order:
  1. `h2` with exact text `ノート`.
  2. A local full-page form with class `.note-gadget-form`.
  3. Either an empty state `.note-empty` or a note list `.note-list`.
- The form is a full-width block below the heading. The list or empty state appears directly below the form so the user's saved result is visually connected to the capture action.
- Use simple, document-flow layout only. Do not introduce modal, drawer, popover, sticky, draggable, or split-pane behavior for notes.
- The note list is a vertical stack. Each note item must render as `.note-item` with `.note-body` before `.note-timestamp`.

### Drawer cleanup

- Add or use a helper named `drawer_ui?` for layout drawer eligibility.
- `drawer_ui?` must evaluate to signed-in users whose `favorite_theme` is not `simple`.
- Gate the hamburger button and drawer DOM with `drawer_ui?`.
- The simple theme must not render `.drawer` or `.drawer-overlay` DOM at all.
- The simple menu remains authenticated + simple-theme only: render `common/menu` only when `user_signed_in? && favorite_theme == 'simple'`.
- Do not use `!drawer_ui?` as the simple menu condition, because unauthenticated pages must not render the authenticated menu.

## 2. Typography and copy

### Required copy

- Heading: `h2` text must be exactly `ノート`.
- Form label: the textarea label must be exactly `メモ`.
- Submit value: the submit control value must be exactly `保存`.
- Empty state: when the current user has no notes, render exact text `メモはまだありません` inside `.note-empty`.

### Text presentation

- Match the existing simple theme scale: compact, plain, and server-rendered.
- The `h2` should remain visually close to the existing Phase 12 placeholder heading: approximately 14px, bold, with short bottom spacing.
- Form label text should be legible and visible, not screen-reader-only.
- Note body text should preserve user-entered line breaks enough to read multi-line notes. Prefer CSS such as `white-space: pre-wrap` on `.note-body`; do not render note bodies with `raw`.
- Timestamp text uses the deterministic format `%Y-%m-%d %H:%M`, rendered from each note's `created_at`.
- Timestamp copy is metadata only. Do not prepend extra localized words such as `作成日時:` unless tests are updated to treat that as presentation; the stable value is the formatted timestamp.

## 3. Color and visual treatment

- All new note gadget styles must live in `app/assets/stylesheets/welcome.css.scss` under the existing `.simple { }` scope.
- Required style selectors are:
  - `.simple .note-gadget`
  - `.simple .note-gadget-form`
  - `.simple .note-empty`
  - `.simple .note-list`
  - `.simple .note-item`
  - `.simple .note-body`
  - `.simple .note-timestamp`
- Do not add note gadget CSS to `common.css.scss`, `themes/simple.css.scss`, or unscoped global selectors.
- Visual treatment should stay neutral and low contrast, aligned with the existing simple theme:
  - Use inherited text color for primary note content.
  - Use a subtle border or top divider for `.note-item` separation.
  - Use a muted gray tone for `.note-timestamp`.
  - Use white or transparent backgrounds; do not introduce a new accent palette.
- The textarea and submit button should use native form controls with modest spacing. Do not add custom iconography, animation, or image assets.
- The active tab styling from Phase 12 remains the tab affordance; the note gadget must not introduce a second active/navigation treatment.

## 4. Interaction states

### Note form

- Use a local full-page Rails form that submits to the existing notes create route. The form must have class `.note-gadget-form`.
- The form must contain:
  - A visible label with text `メモ`.
  - A textarea named `note[body]`.
  - A submit control whose value is `保存`.
- The textarea should be multi-line and sized for quick capture, with roughly 4 rows as the default target.
- Saving is explicit only. No autosave, debounce, background request, optimistic update, or client-side note persistence is allowed.
- After a successful save, the existing controller redirect contract applies: the page returns to the root path with `tab=notes`, and `#notes-tab-panel` is visible.
- Validation failure behavior is not redesigned in this phase. Preserve the existing full-page server response/redirect pattern from `NotesController`.

### Note list

- Notes must render in reverse chronological order, newest first.
- The newly saved note must appear at the top of `.note-list` after redirect.
- When there are no notes for the current user, render `.note-empty` instead of an empty `.note-list`.
- Another user's notes must not render anywhere inside `#notes-tab-panel`.

### Drawer

- For modern and classic signed-in pages, the hamburger and drawer continue to render and behave as before.
- For simple signed-in pages, there is no hamburger, `.drawer`, or `.drawer-overlay` DOM. This is a rendering contract, not just a hidden-state contract.

## 5. Responsive behavior

- The note gadget remains inside the existing simple theme page flow and follows the same wrapper width and padding behavior as the portal.
- At mobile widths, the form, textarea, empty state, and list must be single column and full available width.
- The textarea should not overflow the viewport. Set width to fill the container with box sizing that includes padding and border.
- `.note-item` content must wrap naturally. Long note bodies and long unbroken strings must not force horizontal page scrolling.
- Do not add note-specific breakpoints unless the existing simple theme breakpoints are insufficient. Prefer styles that work across desktop, tablet, and mobile without extra layout modes.
- Drawer cleanup must not change responsive behavior for modern/classic drawer UI; it only changes whether drawer DOM is rendered for the simple theme.

## 6. Accessibility and test selectors

### Accessibility contract

- The textarea must be associated with the visible `メモ` label through Rails form helper output or equivalent `for`/`id` attributes.
- The submit control must expose the accessible name `保存`.
- Keep keyboard operation native: tab to textarea, type, tab to submit, press Enter/Space to submit where browser defaults allow.
- Do not remove the existing tab button semantics or `data-simple-tab` hooks from Phase 12.
- The `h2` heading provides the note panel's accessible section heading. Do not add a competing hidden heading with different copy.
- Empty state text must be visible text, not only an ARIA label.
- Note body output must remain HTML-escaped.

### Required selectors and hooks

Note tab and gadget:

- `#notes-tab-panel`
- `#notes-tab-panel .note-gadget`
- `.note-gadget h2`
- `form.note-gadget-form`
- `textarea[name="note[body]"]`
- `input[type="submit"][value="保存"]` or equivalent submit element with value/name `保存`
- `.note-empty`
- `.note-list`
- `.note-item`
- `.note-body`
- `.note-timestamp`

Tabs:

- `button.simple-tab[data-simple-tab="home"]`
- `button.simple-tab[data-simple-tab="notes"]`
- `.simple-tab--active`
- `.simple-tab-panel--hidden`

Drawer cleanup:

- `button.hamburger-btn`
- `.drawer`
- `.drawer-overlay`
- `body.simple`

### Verification requirements

- `WelcomeController` tests should assert the simple-theme Note panel renders `.note-gadget`, the form, `textarea[name="note[body]"]`, submit value `保存`, the empty state, the list structure, reverse chronological order, and current-user-only note visibility.
- Do not add `test/integration/` tests for this phase; Rails-side coverage belongs in `WelcomeController` tests and browser save-flow coverage belongs in Cucumber.
- Layout structure tests should assert:
  - Modern signed-in pages render `button.hamburger-btn`, `.drawer`, and `.drawer-overlay`.
  - Classic signed-in pages render drawer UI.
  - Simple signed-in pages render the authenticated simple menu and do not render `button.hamburger-btn`, `.drawer`, or `.drawer-overlay`.
- Cucumber should cover the browser-visible save flow:
  1. Sign in as a user with simple theme.
  2. Visit the welcome page.
  3. Activate the Note tab via `button.simple-tab[data-simple-tab="notes"]`.
  4. Fill the `メモ` textarea or `textarea[name="note[body]"]`.
  5. Click `保存`.
  6. Assert the URL/query returns to `tab=notes`.
  7. Assert `#notes-tab-panel` is visible and `.note-item:first-child .note-body` contains the saved note.
- Timestamp tests should create notes with fixed, distinct `created_at` values and assert the rendered format `%Y-%m-%d %H:%M`.

## Explicit non-goals

- No new JavaScript for the note gadget.
- No autosave.
- No rich text or markdown editor.
- No inline editing.
- No pagination.
- No delete-note UI.
- No note gadget on modern or classic themes.
- No AJAX, fetch, Turbo, or optimistic UI for note creation.
- No new dependencies, component libraries, icons, fonts, or design system primitives.
- No redesign of the existing simple tab labels or tab-switching behavior.
- No global CSS for note UI outside `.simple { }` in `app/assets/stylesheets/welcome.css.scss`.
