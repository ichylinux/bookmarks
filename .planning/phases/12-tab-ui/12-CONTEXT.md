---
phase: 12
phase_name: Tab UI
phase_slug: tab-ui
milestone: v1.3
created: 2026-04-30
status: ready-to-plan
---

# Phase 12 Context — Tab UI

**Gathered:** 2026-04-30
**Status:** Ready for planning

<domain>

## Phase Boundary

On the **simple** theme only, the welcome page (`WelcomeController#index` / `welcome/index`) gains **「ホーム」** and **「ノート」** tab controls. Clicking switches visibility between the existing portal/grid **home panel** and a **notes panel** (gadget form + list land in Phase 13; this phase only needs the shell: tab chrome, panels, JS switching, and post-redirect behavior). Modern and classic themes show **no** tab UI. All tab markup is gated in ERB with `favorite_theme == 'simple'`; tab-related styles live **only** under `.simple { }` in `welcome.css.scss`, not `common.css.scss`. **`NotesController` already redirects with `tab: 'notes'`** — the welcome view and client script must honor that query param on load.

</domain>

<decisions>

## Implementation Decisions

### Labels and semantics

- **D-01:** Tab labels **`ホーム`** and **`ノート`** (ROADMAP success criteria §1–2). Align copy with REQUIREMENTS bullets that still say English in TRACEABILITY-only areas — implementation follows ROADMAP SC for this milestone.
- **D-02:** **Home panel** = current welcome portal content (`div.portal` + gadgets). **Notes panel** = dedicated container rendered only on simple theme; **empty or placeholder** body acceptable until Phase 13 fills `_note_gadget` (planner should still land structure ERB/CSS/JS hooks that Phase 13 plugs into).

### Tab switching and URL

- **D-03:** **jQuery** `show()` / `hide()` (or equivalent) on the client — **no new JS dependencies** (STATE / PROJECT constraint). No full page reload for tab clicks.
- **D-04:** Support **`?tab=notes`** (and default / `tab=home` or absence = home) so **POST → redirect** from `NotesController` re-opens the Note tab. Read on `$(document).ready` via `URLSearchParams` or equivalent (pattern noted in STATE).
- **D-05:** Non-simple themes: **do not** render tab links or note panel markup in HTML (ROADMAP SC4) — ERB guard is mandatory; JS should **no-op** when `body` is not `.simple` (mirror `menu.js` early-return pattern).

### Layout and placement

- **D-06:** Place tab strip **above** the main welcome content inside the simple-theme-only wrapper — same visual hierarchy as `_menu`-backed navigation; planner picks exact markup (links vs buttons, roles) consistent with existing simple header.

### Claude's Discretion

- Accessible attributes (`role="tablist"` / keyboard) — nice-to-have; not required unless planner adds low-cost wins.
- Exact CSS for active tab underline/color under `.simple`.
- Notes panel skeleton copy (Phase 13 may replace).

</decisions>

<canonical_refs>

## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone and requirements

- `.planning/ROADMAP.md` — Phase 12 goal and success criteria (TAB-01, TAB-02, TAB-03)
- `.planning/REQUIREMENTS.md` — TAB-01–TAB-03 traceability
- `.planning/PROJECT.md` — v1.3 scope, theme naming
- `.planning/STATE.md` — locked tab/redirect/CSS patterns for v1.3

### Prior phase alignment

- `.planning/phases/11-notes-controller/11-CONTEXT.md` — redirect + flash + `tab: 'notes'`
- `.planning/phases/11-notes-controller/11-VERIFICATION.md` — NOTE-01 satisfied before UI

### Code and assets

- `app/views/layouts/application.html.erb` — `body` class `favorite_theme`; simple menu injection
- `app/views/common/_menu.html.erb` — simple theme top navigation patterns
- `app/views/welcome/index.html.erb` — portal grid insertion point for tab panels
- `app/controllers/welcome_controller.rb` — `index`
- `app/controllers/notes_controller.rb` — `redirect_to root_path(tab: 'notes')`
- `app/helpers/welcome_helper.rb` — `favorite_theme`
- `app/assets/stylesheets/welcome.css.scss` — portal/gadget styles; extend under `.simple` for tabs
- `app/assets/stylesheets/themes/simple.css.scss` — `#header { display: none }`, wrapper padding
- `app/assets/javascripts/menu.js` — theme guard pattern for modern drawer (model for **`notes.js` or inline** guarded script)

</canonical_refs>

<code_context>

## Existing Code Insights

### Reusable assets

- **`menu.js`**: `if (!$('body').hasClass('modern')) return;` — use **`hasClass('simple')` positive guard** or inverse for tab script so drawer/modern code paths stay isolated.
- **`NotesController#create`**: success and failure already preserve **`tab: 'notes'`** — tab UI must read params on load.

### Established patterns

- **Theme isolation**: ERB `<% if favorite_theme == 'simple' %>` + SCSS `.simple { }` (STATE Critical Pitfalls: both required).
- **Full-page POST + redirect**: tab state survives only via **query string** (chosen over cookies for this flow).

### Integration points

- Welcome `index` — wrap or partition content into **home** vs **notes** panel nodes.
- Future Phase 13 — notes panel mounts `_note_gadget.html.erb` and list; Phase 12 should leave stable IDs/classes for hooking.

</code_context>

<specifics>

## Specific Ideas

- Match existing simple header feel (`_menu.html.erb` list navigation) so tabs feel native to simple theme.

</specifics>

<deferred>

## Deferred Ideas

- **NOTE-02** (list + gadget) — Phase 13
- **Drawer / pending todos** (extract `drawer_ui` helper, gate drawer overlay on theme) — remain in `.planning/todos/pending/`; not folded into Phase 12

### Reviewed Todos (not folded)

- Drawer helper / drawer-overlay symmetry — unrelated to welcome tab chrome; defer

</deferred>

---

*Phase: 12-tab-ui*
*Context gathered: 2026-04-30*
