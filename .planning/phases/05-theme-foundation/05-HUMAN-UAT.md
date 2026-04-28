---
status: partial
phase: 05-theme-foundation
source: [05-VERIFICATION.md]
started: 2026-04-28T13:40:22Z
updated: 2026-04-28T13:40:22Z
---

## Current Test

[awaiting human testing]

## Tests

### 1. Preferences form save — modern theme
expected: Select モダン, click 保存, verify `<body class="modern">` on next page load
result: [pending]

### 2. Theme revert — clear modern
expected: Select デフォルト after モダン, verify body class clears (no "modern" class)
result: [pending]

### 3. Asset pipeline — no Sprockets errors
expected: Start Rails server, confirm no Sprockets compilation errors for modern.css.scss or menu.js
result: [pending]

### 4. menu.js guard — zero side effects on non-modern page
expected: Load a non-modern page, confirm no JS console errors (guard fires and returns immediately)
result: [pending]

## Summary

total: 4
passed: 0
issues: 0
pending: 4
skipped: 0
blocked: 0

## Gaps
