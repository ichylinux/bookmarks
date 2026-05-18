# Research Summary: v1.26 Visited Link Tracking

**Project:** Bookmarks v1.26 — Visited Link Tracking
**Researched:** 2026-05-18
**Confidence:** HIGH

## Executive Summary

v1.26 adds server-side visited-link tracking to a personal dashboard of RSS feed, Mastodon, and X gadgets. The feature requires **zero new gems and zero new npm packages**. Rails 8.1's built-in `upsert` API handles atomic insert-or-ignore; the existing jQuery delegation pattern handles click interception on AJAX-injected gadget content; server-side CSS class injection at AJAX render time provides cross-device sync without any client-side state management.

All four research strands converge on the same conclusion: this is a well-bounded four-phase build where each phase can be independently verified by the full test suite.

The recommended approach is strict bottom-up: data layer first (migration, model, route, controller), then CSS and view helper, then wiring all three show controllers and views, then the JS click handler. The most critical architectural decision is assigning `@visited_urls` only in the three gadget show actions — not `WelcomeController#index` — which keeps the DB query scoped to AJAX renders only.

The primary risk cluster: URL normalization consistency, jQuery event delegation correctness, and Cucumber test isolation (the `Before` hook must have `VisitedLink.delete_all` added in the same commit as the migration). All three are easy to prevent at implementation time and hard to diagnose after the fact.

---

## Key Findings

### Stack — no new dependencies

- **`ActiveRecord.upsert(unique_by:, update_only: [])`** → MySQL `INSERT ... ON DUPLICATE KEY UPDATE` — atomic, race-safe, single query; no `find_or_create_by` TOCTOU race
- **`UNIQUE INDEX (user_id, url(768))`** — prefix length required for `utf8mb4` on `varchar(2083)` columns; `add_index :visited_links, [:user_id, :url], unique: true, length: { url: 768 }`
- **`$(document).on('click.visitedLinks', '.gadget ol li a[href]', fn)`** — delegation on stable ancestor; gadget content is AJAX-injected so direct `<a>` binding would be lost on re-render
- **`jquery_ujs.js` `$.ajaxPrefilter`** — injects `X-CSRF-Token` globally on DOMContentLoaded; all `$.post` calls in the click handler inherit this automatically; no manual CSRF plumbing needed
- **Sprockets `require_tree .`** — new `visited_links.js` auto-included with no manifest change

### Features — MVP is narrow and complete

**Must-have (P1, LOW complexity — milestone incomplete without these):**
- `visited_links` table + model with `upsert` and `urls_for(user)` scope
- `POST /visited_links` endpoint (CSRF-aware, upsert-or-ignore, 204 response)
- JS delegated click handler (fire-and-forget `$.post`, optimistic `addClass`)
- `@visited_urls` Set assigned in three gadget show actions (not `WelcomeController#index`)
- Visited CSS class injected in three AJAX show partials at render time
- `VisitedLink.delete_all` in Cucumber `Before` hook (same commit as migration)

**Explicitly deferred (no value at personal-app scale):**
- Per-gadget unread/visited counts
- Bulk mark-all-read
- Visit expiry / cleanup job
- Mark-as-unvisited
- History page
- Real-time cross-tab push

### Architecture — two-step render pipeline determines where the class lives

The gadget system has two render steps:

1. **Page load (step 1):** Skeleton partial + `portalLazy.register` — no content links rendered here; no visited state needed here
2. **AJAX (step 2):** `FeedsController#show`, `MastodonAccountsController#show`, `XAccountsController#show` render content links — this is where `@visited_urls = VisitedLink.urls_for(current_user)` is assigned and `class: visited_link_class(@visited_urls, url)` is applied

The JS click handler adds the CSS class **optimistically on click** for immediate visual feedback; the next page reload confirms it from the server-side `@visited_urls` set. This means cross-device sync requires a reload, which is the correct behavior for this app.

New files: `visited_links` migration, `VisitedLink` model, `VisitedLinksController`, `visited_links.js`
Modified files: `FeedsController`, `MastodonAccountsController`, `XAccountsController` (add `@visited_urls`), three show partials (add class), `ApplicationHelper` (add `visited_link_class`), `common.css.scss` (add `.link--visited` rule), `features/support/hooks.rb` (add `VisitedLink.delete_all`)

### Critical Pitfalls

| # | Pitfall | Prevention | Phase |
|---|---------|-----------|-------|
| 1 | **Delegated handler lost after AJAX re-render** | `$(document).on('click.visitedLinks', ...)` not `$('a').on`; call `.off('.visitedLinks')` before bind | Phase 4 |
| 2 | **URL normalization mismatch** | Strip fragments (`url.split('#')[0]`), use `this.href` (DOM-resolved absolute) in JS; identical normalization on write and read in Ruby | Phase 1 |
| 3 | **Cucumber state leakage** | `VisitedLink.delete_all` in `Before` hook **same commit** as migration | Phase 1 |
| 4 | **N+1 per-link query in views** | `VisitedLink.where(user_id:).pluck(:url).to_set` once per controller action; never `exists?` per item | Phase 3 |
| 5 | **CSS specificity conflict** | `.gadget ol li a.link--visited` (0,2,2) beats existing `:visited` rules; define in `common.css.scss` with `:visited` variant | Phase 2 |
| 6 | **TOCTOU upsert race (concurrent tabs)** | `Model.upsert` not `find_or_create_by` | Phase 1 |
| 7 | **WebMock confusion for internal endpoint** | `post /visited_links, params:` is rack dispatch, not HTTP — no `WebMock.stub_request` needed for controller integration tests | Phase 1 |

---

## Roadmap Implications

Suggested 4 phases (starting at Phase 84 — continuing from v1.25's Phase 83):

| Phase | Name | Delivers | Gate |
|-------|------|----------|------|
| 84 | Data Layer + Controller | `visited_links` migration, `VisitedLink` model + `upsert`, `POST /visited_links` controller, route, unique index, Cucumber `Before` hook update, URL normalization spec | tri-suite green; no visible UX change |
| 85 | CSS + View Helper | `.link--visited` in `common.css.scss` (correct specificity), `ApplicationHelper#visited_link_class`, unit + CSS contract tests | tri-suite green; CSS rule exists but never triggered yet |
| 86 | Show Controller + View Wiring | `@visited_urls` Set in 3 show actions, `class:` in 3 show partials, controller tests for class presence/absence; all three gadgets together to verify cross-gadget URL deduplication | tri-suite green; server renders visited class on re-render |
| 87 | JS Click Handler | `visited_links.js` IIFE with namespaced delegation, `data-visited-links-path` on `<body>`, Cucumber E2E extension; end-to-end smoke: click → POST → reload → see class | tri-suite green; full feature live |

No phase has external blockers. Phase 84 is a prerequisite for 85–87; phases 85 and 86 can be swapped in order.

---

## Confidence Assessment

| Area | Level | Reason |
|------|-------|--------|
| Stack (no new deps) | HIGH | Verified against gem versions in Gemfile.lock; Rails 8.1 `upsert` API confirmed |
| Features (MVP scope) | HIGH | Codebase gadget count/structure read directly; personal-app scale confirms deferral decisions |
| Architecture (step-2 render) | HIGH | All three show controllers and partials inspected; AJAX injection pattern confirmed |
| Pitfalls | HIGH | `note_gadget.js` delegation pattern, `hooks.rb` structure, `common.css.scss` specificity all verified directly |

**Overall: HIGH — ready for roadmap**

---

*Research completed: 2026-05-18*
*Ready for roadmap: yes*
