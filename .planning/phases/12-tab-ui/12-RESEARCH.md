# Phase 12: Tab UI — Research

**Researched:** 2026-04-30  
**Domain:** Server-rendered Rails welcome page, simple-theme-only tab strip, jQuery panel toggle, query-param bootstrap for POST/redirect  
**Confidence:** HIGH (scope is small; patterns verified in-repo)

## Summary

Phase 12 adds client-side tabs on the signed-in welcome page **only when** `favorite_theme == 'simple'`. Body already carries `<body class="<%= favorite_theme %>">` [VERIFIED: `app/views/layouts/application.html.erb`], and the simple top menu is already gated with the same predicate [VERIFIED: same layout]. Implementation is straightforward: conditional ERB wraps a tab strip (`button type="button"` with labels **ホーム** / **ノート**), two panels (existing `div.portal` in the home panel; notes shell for Phase 13), and a small JavaScript module that exits immediately unless `$('body').hasClass('simple')` — mirroring the inverse gate in `menu.js` (modern/classic-only) [VERIFIED: `app/assets/javascripts/menu.js`]. `NotesController` already redirects to `root_path(tab: 'notes')` [VERIFIED: `app/controllers/notes_controller.rb`]; the welcome layer must interpret `tab` on full page load (UI-SPEC: `URLSearchParams` on `$(document).ready`) and **must not** change the URL on tab clicks (no `pushState` / `replaceState`) [CITED: `12-CONTEXT.md` D-07]. Tab-only styles belong under `.simple { }` inside `welcome.css.scss` only [VERIFIED: file currently has portal rules but no `.simple` tab block yet — `app/assets/stylesheets/welcome.css.scss`].

**Primary recommendation:** Plan around (1) ERB structure + optional server-side initial visibility from `params[:tab]` for correct first paint, (2) one new guarded JS asset loaded via existing Sprockets `require_tree .`, (3) integration tests flipping `preference.theme` to `'simple'` / `'modern'` (and `'classic'`) asserting presence/absence of tab markup — do not rely on REQUESTMENTS English strings for asserts; ROADMAP/CONTEXT require Japanese labels.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions (Implementation Decisions)

**Labels and semantics**

- **D-01:** Tab labels **`ホーム`** and **`ノート`** (ROADMAP success criteria §1–2). Align copy with REQUIREMENTS bullets that still say English in TRACEABILITY-only areas — implementation follows ROADMAP SC for this milestone.
- **D-02:** **Home panel** = current welcome portal content (`div.portal` + gadgets). **Notes panel** = dedicated container rendered only on simple theme; **empty or placeholder** body acceptable until Phase 13 fills `_note_gadget` (planner should still land structure ERB/CSS/JS hooks that Phase 13 plugs into).

**Tab switching and URL**

- **D-03:** **jQuery** `show()` / `hide()` (or equivalent) on the client — **no new JS dependencies** (STATE / PROJECT constraint). No full page reload for tab clicks.
- **D-04:** Support **`?tab=notes`** (and default / `tab=home` or absence = home) so **POST → redirect** from `NotesController` re-opens the Note tab. Read on `$(document).ready` via `URLSearchParams` or equivalent (pattern noted in STATE).
- **D-05:** Non-simple themes: **do not** render tab links or note panel markup in HTML (ROADMAP SC4) — ERB guard is mandatory; JS should **no-op** when `body` is not `.simple` (mirror `menu.js` early-return pattern).
- **D-07:** **Client-side tab clicks do not change the browser URL** — no `history.pushState` / `replaceState` in Phase 12. The address bar’s `?tab=` is set **only by the server** on redirect (and read on full page load). Panel switching after load is **display-only** via jQuery; this satisfies “no reload on tab click” without growing history entries on every switch. If bookmarkable/shareable tab URLs after client switches become a product requirement, treat as a follow-up phase or backlog item (see Deferred Ideas).
- **D-08:** Tab triggers are **`button type="button"`** elements, styled to match the look of simple-theme top nav in `common/_menu.html.erb` (list, spacing, affordance). Do **not** use `<a href="#">`, `javascript:`, or `link_to` + `preventDefault` as the primary pattern — reduces accidental navigation, form-submit edge cases, and focus quirks.

**Layout and placement**

- **D-06:** Place tab strip **above** the main welcome content inside the simple-theme-only wrapper — same visual hierarchy as `_menu`-backed navigation; **D-08** locks the control element type while allowing CSS to mirror that nav.

### Claude's Discretion

- Accessible attributes (`role="tablist"` / `aria-selected` / arrow keys) — nice-to-have layered on **D-08** buttons; not required unless planner adds low-cost wins.
- Exact CSS for active tab underline/color under `.simple`.
- Notes panel skeleton copy (Phase 13 may replace).

### Deferred Ideas (OUT OF SCOPE)

- **Bookmarkable tab URL after client-side switches** (`pushState` / syncing `?tab=` on every click) — explicitly **out of scope** for Phase 12 per **D-07**; promote to backlog if sharing/bookmarking tab state matters.
- **NOTE-02** (list + gadget) — Phase 13
- **Drawer / pending todos** (extract `drawer_ui` helper, gate drawer overlay on theme) — remain in `.planning/todos/pending/`; not folded into Phase 12

### Reviewed Todos (not folded)

- Drawer helper / drawer-overlay symmetry — unrelated to welcome tab chrome; defer
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description (REQUIREMENTS.md) | Research support |
|----|-------------------------------|------------------|
| TAB-01 | User sees Home/Note tab links on simple welcome (traceability English; **implement ホーム/ノート** per ROADMAP) | ERB guard `favorite_theme == 'simple'` + two `button type="button"` + `.simple` SCSS in `welcome.css.scss` |
| TAB-02 | Click Note → note panel; Home → portal; no reload | jQuery show/hide on panels; buttons not anchors; no navigation |
| TAB-03 | After save, redirect lands on Note tab | Server already adds `?tab=notes` [VERIFIED: `NotesController`]; client + optional SSR initial state must show notes panel on load |
</phase_requirements>

## Architectural Responsibility Map

| Capability | Primary tier | Secondary tier | Rationale |
|------------|--------------|----------------|-----------|
| Tab markup & initial `tab=` interpretation | Frontend server (ERB) | — | SSR controls what exists in DOM per theme and can set initial panel visibility |
| Click-to-switch panels without reload | Browser (jQuery) | — | Display-only toggle; URL unchanged per D-07 |
| Post-save “open notes tab” | API redirect + browser load | Welcome ERB/JS | Redirect URL carries `tab=notes`; welcome layer honors it once per load |
| Theme isolation | ERB + SCSS scope | JS guard | Non-simple themes omit DOM; CSS scoped so accidental leakage is harder |

## Existing implementation and theme isolation patterns

- **Body theme class:** `application.html.erb` sets `<body class="<%= favorite_theme %>">` [VERIFIED: `welcome_helper.rb` returns `preference.theme.presence || 'modern'` when signed in with preference].
- **Simple-only chrome:** `_menu` renders only when `user_signed_in? && favorite_theme == 'simple'` [VERIFIED: layout]. Tabs should follow the **same predicate** so modern/classic never receive tab/note-panel HTML.
- **Drawer/menu JS isolation:** `menu.js` attaches drawer behavior only when `body` has `modern` **or** `classic` — not `simple` [VERIFIED: `menu.js` lines 2–31]. Tab script should use **`if (!$('body').hasClass('simple')) return`** (positive guard recommended in UI-SPEC) so simple never runs drawer hooks and classic/modern never run tab hooks.
- **Welcome content:** `welcome/index.html.erb` is only `div.portal` + inline sortable script [VERIFIED]. Portal layout POST is unchanged by tabs if the portal remains inside the home panel and sortable selectors stay valid.
- **Styles:** `.header` / `ul.navigation` for simple menu live in `common.css.scss` (unchanged); **new tab rules must not** be added there — extend `welcome.css.scss` under `.simple { … }` per ROADMAP SC5 / STATE pitfalls [VERIFIED: `welcome.css.scss` has no `.simple` block yet; `themes/simple.css.scss` only hides `#header` and pads `.wrapper`].
- **Asset pipeline:** `application.js` uses Sprockets `require_tree .` so a new sibling file under `app/assets/javascripts/` is picked up automatically [VERIFIED: `application.js`] — explicit `require` line not strictly required unless load order matters (tab code is standalone).

## Files likely modified or created

| Path | Role |
|------|------|
| `app/views/welcome/index.html.erb` | Wrap simple-only tab strip + two panels; keep portal inside home panel |
| `app/assets/stylesheets/welcome.css.scss` | Add `.simple { }` rules for tab row, buttons, panels, active state |
| `app/assets/javascripts/notes_tabs.js` (name discretionary) | `$(function(){ … })`; guard `simple`; `URLSearchParams`; click handlers |
| Optional `app/views/welcome/_simple_tabs.html.erb` | Keep `index` readable if markup grows |

**Likely untouched for Phase 12:** `NotesController`, `welcome_controller.rb` logic (unless planner adds explicit `@initial_tab` — optional), `themes/simple.css.scss` for tab specifics (tab CSS belongs in `welcome.css.scss` per constraints), `common.css.scss`.

## UI and JS implementation approach

**Markup (HIGH confidence, aligned with CONTEXT/UI-SPEC):**

- Conditional: `<% if favorite_theme == 'simple' %> … <% else %> current single `div.portal` only? <% end %>`. For non-simple, today’s layout is one portal — preserving that avoids duplicate markup. **Planner choice:** Either duplicate the portal block in both branches (bad) or use `<% if … %>` only around tab chrome + wrapper + notes shell while portal stays shared (still need panels — typically structure is: tabs; then `home_panel` contains existing portal; `notes_panel` for Phase 13).
- Buttons: `<button type="button">ホーム</button>` and same for **ノート** — satisfies D-08.
- Stable hooks for Phase 13: single wrapper `id` or class on notes panel (e.g. `#notes-tab-panel`) [ASSUMED naming — discretion].

**Initial tab state (HIGH for behavior, MEDIUM for technique):**

- **UI-SPEC** requires interpreting `tab` via `URLSearchParams` on ready. Optionally **combine** with ERB: set CSS classes or inline `hidden`/`style` from `params[:tab] == 'notes'` so first paint matches before JS runs [ASSUMED optimization — avoids brief wrong panel if JS deferred; planner should justify if testing FOUC].

**JS (HIGH):**

- On ready: parse `window.location.search`; if `tab=notes`, show notes panel / hide home; else home default (including unknown `tab` values → home per UI-SPEC).
- Clicks: toggle panels, update active styling (classes on buttons), **no** URL APIs.
- Do not submit forms; buttons are `type="button"` (D-08).

**Visual alignment:** Match `ul.navigation` feel from `common.css.scss` `.header` (12px lineage, inline-block, ~20px line box) — detailed numbers in `12-UI-SPEC.md` §Spacing/Typography [CITED: `12-UI-SPEC.md`].

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Rails | 8.1.x [VERIFIED: `Gemfile.lock` → `rails (8.1.3)`] | SSR, routing, flash | Existing app |
| jQuery via jquery-rails | 4.6.x [VERIFIED: `Gemfile.lock` `jquery-rails (4.6.1)`] | DOM + event handlers | Project constraint |
| jquery-ui-rails | 8.0.x [VERIFIED: `Gemfile.lock`] | Existing sortable on portal | Already on welcome page |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|---------|
| jQuery toggle | Stimulus/Vue/webpack chunk | Forbidden — zero new deps / pattern lock |
| `pushState` for tabs | Static query + SSR | Deferred explicitly (D-07) |

**Installation:** none — reuse existing gems [VERIFIED].

## Architecture Patterns — data flow

```mermaid
flowchart LR
  subgraph load [Full page load]
    A["GET /?tab=optional"] --> B["ERB: theme simple?"]
    B -->|"no"| C["Portal only DOM"]
    B -->|"yes"| D["Tabs + panels DOM"]
    D --> E["JS: URLSearchParams tab"]
    E --> F["Panels visible"]
  end
  subgraph click [Tab click]
    G["button click"] --> H["show/hide panels"]
    H --> I["URL unchanged"]
  end
  subgraph save [Note save]
    J["POST /notes"] --> K["Redirect /?tab=notes"]
    K --> A
  end
```

### Anti-patterns

- Putting tab selectors only in CSS without hiding tab HTML on non-simple — fails ROADMAP SC4 if markup leaks.
- Using `<a href="#">` for tabs — violates D-08.
- `history.pushState` on tab clicks — violates D-07 / deferred backlog.

## Don't Hand-Roll

| Problem | Don’t build | Use instead | Why |
|---------|-------------|-------------|-----|
| Tab toggling SPA framework | Client router / new bundle | jQuery show/hide | Locked stack |
| Custom URL syncing | pushState shim | Server redirect only | Out of scope D-07 |

## Common Pitfalls (risks)

### TAB theme leakage via CSS or DOM

**What goes wrong:** Tab chrome visible on classic/modern, or selectors in global CSS affecting other pages.  
**Why:** Only ERB gate or only global CSS guard — STATE warns both are needed.  
**Avoid:** `_simple`/`favorite_theme == 'simple'` for HTML; tab rules nested under `.simple` in **`welcome.css.scss` only**.  
**Warning signs:** `assert_select` finds tab buttons when `theme: 'modern'`.

### Sortable / portal layout regression

**What goes wrong:** Moving `div.portal` breaks `#column_*` selectors in `collect_portal_layout_params` or `.gadgets` sortable wiring.  
**Avoid:** Keep portal subtree structure inside home panel unchanged.  
**Source:** `[VERIFIED: welcome/index.html.erb]` embedded script posts to `save_state`.

### Fragile asserts on REQUIREMENTS English

**What goes wrong:** Tests look for `"Home"` / `"Note"` but shipped copy is Japanese.  
**Avoid:** Assert button text `"ホーム"`, `"ノート"` or `data-tab` hooks.  
**Source:** REQUIREMENTS TAB-01/02 wording vs CONTEXT D-01.

### XSS / reflection from `tab` query

**What goes wrong:** Echoing raw `params[:tab]` into HTML or scripts.  
**Avoid:** Branch on allowed values (`notes` vs default) server-side for optional SSR hints; never interpolate param into executable JS. Standard Rails escaping handles text nodes.  
**Confidence:** MEDIUM — OWASP-aligned pattern.

### Assuming `follow_redirect!` asserts active tab panel

**What goes wrong:** `notes_controller_test` already asserts redirect URL [VERIFIED]; it does **not** assert HTML panel state — Phase 12 needs welcome-level integration coverage for TAB-03 end-to-end if required by verification policy.

### Load order collisions

**What goes wrong:** Rare — unless new script interferes alphabetically before jQuery (`require_tree` loads after explicit requires). Tab file should rely on globals after `jquery` already required — **[VERIFIED: `application.js` order]** safe for new `.js` in same directory.

## Test / verification strategy

| Goal | Approach |
|------|----------|
| TAB-01 / SC1 | Integration: sign in, `preference.update!(theme: 'simple')`, `get root_path`, assert two buttons with exact Japanese labels |
| TAB-02 | Same test file: optionally use `selenium`/system test for no full reload — or assert DOM structure + manual UAT; **minimal approach:** Cucumber/feature if project standard for browser tests [NONE found grep `*.feature` for welcome — LOW: may need new feature or rails system test]; **plannable:** request capybara/rails system test verifying two GETs unchanged path without server round-trip harder — **recommended:** planner uses integration for markup + separates “no reload” to manual UAT or system test tier |
| TAB-03 | `sign_in`, `post notes_path, …`, `follow_redirect!`, `assert_select` notes panel marker visible **or** simulate `get root_path(tab: 'notes')` with simple theme and assert notes panel lacks `hidden` / has expected class |
| SC4 non-simple | `theme: 'modern'` and `'classic'`, refute presence of tab buttons wrapper or `#notes-tab-panel` IDs agreed in plan |

**Existing tests to extend or mirror:**  
`NotesControllerTest#test_successful_create` — redirect destination [VERIFIED: `notes_controller_test.rb`].  
`WelcomeController::*` — fixture user + preference patterns [VERIFIED: `welcome_controller/welcome_controller_test.rb`, `layout_structure_test.rb`].

## Validation Architecture

> `workflow.nyquist_validation`: **true** [VERIFIED: `.planning/config.json`]

### Test framework

| Property | Value |
|----------|-------|
| Framework | Minitest + `ActionDispatch::IntegrationTest` [VERIFIED: existing controller tests] |
| Config file | none dedicated — Rails default |
| Quick run command | `bin/rails test test/controllers/welcome_controller/ -x` |
| Full suite command | `bin/rails test` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test type | Automated command | Status |
|--------|----------|------------|-------------------|--------|
| TAB-01 | Tab buttons visible simple only | Integration | `bin/rails test test/controllers/welcome_controller/... -n /simple/` — file TBD | Wave 0: add assertions |
| TAB-02 | Panels toggle markup / system for no reload | Integration + optional system | Planner splits “markup switch” vs “no reload” | Partial without system |
| TAB-03 | Load with `tab=notes` shows notes panel | Integration | `get root_path(tab: 'notes')` + asserts | Fits IntegrationTest |

### Wave 0 Gaps

- [ ] Dedicated test method(s) for `theme: 'simple'` tab markup absent/present vs modern/classic
- [ ] `get root_path(tab: 'notes')` + panel visibility contract (class or landmark in ERB agreed in PLAN)
- [ ] Optional system/Capybara scenario if “no reload” MUST be automated (not in repo for welcome tabs yet) `[VERIFIED: no matching *.feature]`

### Sampling rate suggest

| Gate | Command |
|------|---------|
| Per-commit | targeted welcome + notes controller tests |
| Phase gate | `bin/rails test` green |

## Security Domain

Applicable surface is minimal: **`tab`** is UX state, not authorization. Threats: reflective XSS if mishandled; low risk if branching on enum-like values only. Drawer and CSRF unrelated to Phase 12 except preserving existing portal CSRF handling for layout saves.

| ASVS-relevant area | Applies | Note |
|--------------------|---------|------|
| V5 Input validation | Marginally | Treat `tab` as untrusted category string; whitelist `notes` / default home |

## Project Constraints (from .cursor/rules/)

**.cursor/rules/` does not exist** in project root [VERIFIED: path absent]. Follow default user rules only.

## Assumptions Log

| # | Claim | Risk if wrong |
|---|-------|---------------|
| A1 | Optional SSR initial visibility from `params[:tab]` is allowed and helps FOUC — not explicitly mandated | Negligible — pure JS satisfies D-04 if SSR skipped |
| A2 | `URLSearchParams` available in targeted browsers — acceptable modern baseline | MEDIUM for very old browsers; likely OK per existing stack |

## Open Questions

1. **Automation level for “no page reload” (TAB-02 / SC2)** — Integration tests cannot trivially distinguish client-side toggle from navigation without browser driver. Recommendation: markup + redirect tests automated; no-reload assertion in PLAN as system/Capybara or UAT checklist.
2. **Partial extraction** (`_simple_tabs.html.erb`) — purely organizational; planner decides based on PLAN readability.

## Environment Availability

**Step 2.6: SKIPPED** — no external services beyond Ruby/Rails test stack already used [VERIFIED: existing tests].

## Sources

### Primary [VERIFIED / CITED codebase]

| Artifact | Paths |
|----------|-------|
| Layout & theme injection | `app/views/layouts/application.html.erb`, `welcome_helper.rb` |
| Redirect | `app/controllers/notes_controller.rb`, `notes_controller_test.rb` |
| Welcome markup | `app/views/welcome/index.html.erb` |
| Menu guard reference | `app/assets/javascripts/menu.js`, `app/views/common/_menu.html.erb`, `common.css.scss` (~`.header`) |
| Decisions UI-SPEC | `.planning/phases/12-tab-ui/12-CONTEXT.md`, `12-UI-SPEC.md`, `ROADMAP.md`, `STATE.md`, `REQUIREMENTS.md` |

---

## Metadata

**Confidence breakdown:** Stack HIGH · Architecture HIGH · Pitfalls HIGH (tabular STATE guidance).  
**Valid until:** ~30 days unless theme/layout refactors precede Phase 12.
