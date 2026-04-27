# Phase 3 — Technical Research: Modernize application scripts

**Status:** Complete  
**Phase:** 3 — modernize-application-scripts

## Question answered

What must the planner know to replace `var`, align jQuery `this` with STYL-02, and keep Sprockets / UJS / `.js.erb` behavior identical?

## Summary

- **ESLint** already applies `js.configs.recommended` (includes `no-var`) to `app/assets/javascripts/**/*.js` via `eslint.config.mjs`. Phase 3 work is to **make source match rules** without changing runtime semantics.
- **Sprockets** concatenates files under `//= require_tree .`; each file is a **script** scope (not ES modules). Top-level `const`/`let` do not create `window.*` names the way `var` can in sloppy scripts; for **namespace objects** that must remain addressable as `todos` / `feeds` / `calendars` for other scripts, use **`window.name = window.name || {}` + `const name = window.name`** to preserve duplicate-load guards and global visibility where required.
- **jQuery `this`:** Handlers that rely on jQuery’s bound element (e.g. `$(this)`, `.each(function(){ ... $(this) })`) must remain **`function`**, not arrow functions. Outer `$(document).ready` may use an **arrow** only if the callback body does not use jQuery’s `this` (per `03-CONTEXT.md` D-04–D-06).
- **`cable.js`:** IIFE `function() { this.App || ... }.call(this)` uses **dynamic `this`**. Do not convert that IIFE to an arrow. No `var` in file today; leave pattern intact.
- **STYL-04:** After edits, `RAILS_ENV=production bin/rails assets:precompile` (or project-documented equivalent) should still succeed, matching Phase 2 expectations.

## File inventory and notes

| File | `var` / scope notes | jQuery `this` |
|------|---------------------|---------------|
| `todos.js` | `if (typeof todos === "undefined") { var todos = {} }` — **replace** with `window.todos` init + `const todos` alias. Inner `var` in handlers → `const`/`let`. | `.delegate` / `.each` callbacks use `this` — keep `function`. |
| `feeds.js` | Top `var feeds = {}`; `for (var i = 0; ...)`. | No `this` in handlers — arrows optional where clear. |
| `calendars.js` | `var calendars = {}` | Same as feeds. |
| `bookmark_gadget.js` | Many `var` in ready + click handler. | **`.on('click', function () {` must stay `function`** (`this` = header). |
| `bookmarks.js` | `var` in `blur` handler | **Outer `#bookmark_url` handler must stay `function`** (`this` = input). |
| `application.js` | Manifest only | — |
| `cable.js` | No `var` | Preserve IIFE. |

## Risks and mitigations

- **Reordering / duplicate load:** Use `window.<ns> = window.<ns> || {}` before `const <ns> = window.<ns>` for namespace objects, mirroring the existing `todos` guard intent.
- **Regressions:** `yarn run lint` after every substantive edit; `assets:precompile` in STYL-04 plan; manual smoke of bookmark title fetch, gadgets, feeds/todos (per `03-CONTEXT` / VERI in later phase).

## Validation Architecture

**Nyquist / Dimension 8:** Feedback loop for this phase is **not** a new JS test framework; it reuses the **ESLint** command and **Rails asset** build.

| Layer | Tool | When |
|------|------|------|
| Fast | `yarn run lint` | After each task that touches `app/assets/javascripts/**/*.js` |
| Build | `bin/rails assets:precompile` (see README / Phase 2) | After Babel- or wide-reaching edits (STYL-04) |
| App tests | `bin/rails test` (not expanded in v1.1 for JS-only, but no new Ruby failures) | Optional if Ruby touched; Phase 3 should not change Ruby |

**Dimension 8:** Every plan should tie verification to **repeatable commands** and **grep-able acceptance** (e.g. no `var` except documented `eslint-disable-next-line`).

## RESEARCH COMPLETE

This research is ready for `03-PLAN.md` generation and `03-VALIDATION.md` (Nyquist) alignment.
