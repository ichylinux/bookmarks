---
phase: 03-modernize-application-scripts
fixed_at: 2026-04-27T00:00:00Z
review_path: .planning/phases/03-modernize-application-scripts/03-REVIEW.md
iteration: 1
findings_in_scope: 5
fixed: 5
skipped: 0
status: all_fixed
---

# Phase 03: Code Review Fix Report

**Fixed at:** 2026-04-27
**Source review:** .planning/phases/03-modernize-application-scripts/03-REVIEW.md
**Iteration:** 1

**Summary:**
- Findings in scope: 5
- Fixed: 5
- Skipped: 0

## Fixed Issues

### CR-01: JSON.parse on untrusted localStorage value throws uncaught exception

**Files modified:** `app/assets/javascripts/bookmark_gadget.js`
**Commits:** `f67c0b0`, `19ca61d`
**Applied fix:** Replaced the bare `JSON.parse(stored)` one-liner with a
`try/catch` block that returns `[]` on any parse failure. Also guards the
no-stored-value case with an early `if (!stored) return []`. Used ES2019
optional catch binding (`catch {}`) to avoid triggering the `no-unused-vars`
ESLint rule on an intentionally unused error variable.

### WR-01: $.delegate() is removed in jQuery 3 — runtime error on upgrade

**Files modified:** `app/assets/javascripts/todos.js`
**Commit:** `765a4b7`
**Applied fix:** Replaced both `.delegate(childSelector, event, fn)` calls in
`todos.init` with the equivalent `.on(event, childSelector, fn)` signature
(jQuery 1.7+). Argument order is swapped per the `.on()` API — verified
against the review description.

### WR-02: feeds.js sets params[i].value = null

**Files modified:** `app/assets/javascripts/feeds.js`
**Commit:** `e08112e`
**Applied fix:** Changed `params[i].value = null` to
`params[i].value = '';  // omit id so server treats this as a new record`.
An empty string is unambiguous across all jQuery versions; `null` relied on
undocumented coercion behaviour.

### WR-03: Loose equality == used for string comparisons throughout feeds.js

**Files modified:** `app/assets/javascripts/feeds.js`
**Commit:** `9bdaa20`
**Applied fix:** Replaced all four `==` comparisons with `===` at lines 9,
16, 18, and 24. All comparands are strings at runtime so semantics are
identical; strict equality is now consistent with the rest of the codebase.

### WR-04: const alias of window.* namespace severs live reference

**Files modified:** `app/assets/javascripts/calendars.js`,
`app/assets/javascripts/feeds.js`, `app/assets/javascripts/todos.js`
**Commit:** `086e480`
**Applied fix:** Added a NOTE comment above each `const` alias clarifying
that it captures the `window.*` reference at parse time, that `window.*`
remains the authoritative global, and that reassigning it in another file
would make the alias stale. Chose the lower-risk documentation path (no
code restructuring) as instructed.

---

_Fixed: 2026-04-27_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
