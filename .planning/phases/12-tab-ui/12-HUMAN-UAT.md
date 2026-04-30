---
status: partial
phase: 12-tab-ui
source: [12-VERIFICATION.md]
started: 2026-04-30T09:00:00Z
updated: 2026-04-30T09:00:00Z
---

# Phase 12 — Human UAT

## Current Test

Awaiting human browser verification for TAB-02 no-reload tab switching.

## Tests

### 1. TAB-02: Simple-theme tab switching does not reload

expected: >
  When signed in with the simple theme, visiting `/` shows the Home panel by default.
  Clicking `ノート` hides the Home panel and shows the Note panel without a full
  document navigation. Clicking `ホーム` reverses the visible panel. The address
  bar query string does not change on tab clicks.

result: pending

steps:
  - Sign in with a user whose preference theme is `simple`.
  - Visit `/`.
  - Open browser developer tools Network tab and preserve logs if useful.
  - Click `ノート`.
  - Confirm the home portal is hidden and the note panel is visible.
  - Confirm no new document navigation occurred.
  - Confirm the address bar query did not change because of the click.
  - Click `ホーム`.
  - Confirm the portal returns and the address bar query still did not change.

## Summary

total: 1
passed: 0
issues: 0
pending: 1
skipped: 0
blocked: 0

## Gaps

None recorded yet.
