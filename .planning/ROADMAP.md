# Roadmap: Bookmarks

## Milestones

- ✅ **v1.25 — Portal Column Width Ratios** — Phases 80–83 (shipped 2026-05-18) — desktop per-column ratio sliders; mobile unchanged
- ✅ **v1.24 — Mobile Column Lazy Loading** — Phases 76–79 (shipped 2026-05-17) — [archived](milestones/v1.24-ROADMAP.md)
- ✅ **v1.23 — Icon Display Preference** — Phases 73–75 (shipped 2026-05-17) — [archived](milestones/v1.23-ROADMAP.md)
- ✅ **v1.22 — Landing at Root** — Phases 70–72 (shipped 2026-05-17) — [archived](milestones/v1.22-ROADMAP.md)
- ✅ **v1.21 — X Gadget Tweet Count Preference** — Phase 69 (shipped 2026-05-16) — [archived](milestones/v1.21-ROADMAP.md)
- ✅ **v1.20 — Column Count Preference** — Phases 67–68 (shipped 2026-05-15) — [archived](milestones/v1.20-ROADMAP.md)
- ✅ **v1.19 — HTTP test stubs → WebMock** — Phases 64–66 (shipped 2026-05-14) — [archived](milestones/v1.19-ROADMAP.md)
- ✅ **v1.18 — X (Twitter) Account Following** — Phases 60–63 (shipped 2026-05-14) — [archived](milestones/v1.18-ROADMAP.md)
- ✅ **v1.17 — Email Registration for X/Twitter Users** — Phases 57–59 (shipped 2026-05-13) — [archived](milestones/v1.17-ROADMAP.md)
- ✅ **v1.16 — Mastodon Account Following** — Phases 52–56 (shipped 2026-05-12) — [archived](milestones/v1.16-ROADMAP.md)
- ✅ **v1.15 — CSS & UI Polish** — Phases 49–51 (shipped 2026-05-11) — [archived](milestones/v1.15-ROADMAP.md)
- ✅ **v1.14 — Landing Page Changelog** — Phases 46–48 (shipped 2026-05-10) — [archived](milestones/v1.14-ROADMAP.md)
- ✅ **v1.13 — Root Entry Redirect to Landing for Guests** — Phases 43–45 (shipped 2026-05-08) — [archived](milestones/v1.13-ROADMAP.md)
- ✅ **v1.12 — Landing Page for User Acquisition (Phase 1)** — Phases 40–42 (shipped 2026-05-08) — [archived](milestones/v1.12-ROADMAP.md)
- ✅ **v1.11 — Device-aware Font Size Baseline** — Phases 37–39 (shipped 2026-05-06) — [archived](milestones/v1.11-ROADMAP.md)
- ⚠️ **v1.10 — HTTP Client Consolidation** — Phases 34–36 (deferred 2026-05-06)
- ✅ **v1.9 — Mobile Regression Hardening** — Phases 33–33.2 (shipped 2026-05-05) — [archived](milestones/v1.9-ROADMAP.md)
- ✅ **v1.8 — Mobile UX Enhancement** — Phases 29–32.1 (shipped 2026-05-05) — [archived](milestones/v1.8-ROADMAP.md)
- ✅ **v1.7 — Mobile Portal Layout** — Phases 26–28 (shipped 2026-05-04) — [archived](milestones/v1.7-ROADMAP.md)
- ✅ **v1.6 — Note Gadget for All Themes** — Phases 23–25 (shipped 2026-05-04) — [archived](milestones/v1.6-ROADMAP.md)
- ✅ **v1.5 — Verification Debt Cleanup** — Phases 19–22 (shipped 2026-05-04) — [archived](milestones/v1.5-ROADMAP.md)
- ✅ **v1.4 — Internationalization** — Phases 14–18.2 (shipped 2026-05-03) — [archived](milestones/v1.4-ROADMAP.md)
- ✅ **v1.3 — Quick Note Gadget** — Phases 10–13 (shipped 2026-04-30) — [archived](milestones/v1.3-ROADMAP.md)
- ✅ **v1.2 — Modern Theme** — Phases 5–9 (shipped 2026-04-29) — [archived](milestones/v1.2-ROADMAP.md)
- ✅ **v1.1 — Modern JavaScript** — Phases 2–4 (shipped 2026-04-27) — [archived](milestones/v1.1-ROADMAP.md)

## Phases

### v1.25 — Portal Column Width Ratios (shipped 2026-05-18)

**Overview:** Replace equal fixed column widths on desktop with user-configured ratios (sum 100%) via sliders on the preferences page. Mobile portal behavior unchanged.

| Phase | Name | Goal | Requirements |
|-------|------|------|----------------|
| [x] 80 | Column Width Data Model | Persist and validate per-user column width ratios; equal-split defaults | COLW-01, COLW-02 |
| [x] 81 | Preferences Ratio Sliders | Settings UI with linked sliders, save/reload, ja/en | COLW-03, COLW-04 |
| [x] 82 | Desktop Portal Layout | Apply ratios on desktop welcome portal; preserve mobile + column-count safety | COLW-05, COLW-06, COLW-07 |
| [x] 83 | Tests & Tri-suite Gate | Minitest, locale parity, Cucumber if needed, tri-suite green | COLW-08, COLW-09 |

---

#### Phase 80: Column Width Data Model

**Goal:** `preferences` stores an array of column width percentages (length = `portal_column_count`, sum = 100); validation and defaults match today's equal split when unset.

**Depends on:** Phase 79 (v1.24)

**Requirements:** COLW-01, COLW-02

**Success criteria:**
1. Migration adds a nullable or default-backed column (e.g. JSON) for width ratios; existing users behave as equal split without manual migration steps.
2. `Preference` rejects arrays of wrong length, non-positive entries, or sum ≠ 100.
3. `default_preference` and column-count change paths assign equal split for the active column count.
4. Strong params permit the new attribute; unit tests cover valid, invalid, and default cases.

---

#### Phase 81: Preferences Ratio Sliders

**Goal:** User adjusts one slider per column on the preferences page; values stay linked to 100% total and persist on save.

**Depends on:** Phase 80

**Requirements:** COLW-03, COLW-04

**Success criteria:**
1. Preferences form renders N sliders when `portal_column_count` is N (3 or 4).
2. Client-side logic keeps the displayed total at 100% while dragging (e.g. redistribute delta across other columns).
3. PATCH/POST round-trip saves and reloads the same ratios; ja/en labels present with parity test.
4. No new npm dependencies; Sprockets-compatible JS only.

---

#### Phase 82: Desktop Portal Layout

**Goal:** Desktop welcome page columns use saved flex/width ratios; mobile tab layout and v1.20 column-count behavior unchanged.

**Depends on:** Phase 81

**Requirements:** COLW-05, COLW-06, COLW-07

**Success criteria:**
1. At `min-width: $portal-mobile-breakpoint`, each `.portal-column` width reflects saved ratios (CSS variables or inline flex-basis from server).
2. Below breakpoint, columns remain full-width in the tab track; ratio CSS does not break swipe/tab UX.
3. Unequal 4-column example visibly wider/narrower on desktop in browser smoke test.
4. Switching 3↔4 columns does not break gadget placement; equal default applies when ratios invalid for new count.

---

#### Phase 83: Tests & Tri-suite Gate

**Goal:** Automated coverage and green tri-suite at milestone close.

**Depends on:** Phase 82

**Requirements:** COLW-08, COLW-09

**Success criteria:**
1. Minitest: model validation, preferences controller save, layout structure tests for unequal 3- and 4-column desktop output.
2. Locale parity test for new `portal_column_width*` keys.
3. `yarn run lint`, `bin/rails test`, `bundle exec rake dad:test` all green (Cucumber flake rerun policy per CLAUDE.md).

---

<details>
<summary>✅ v1.24 — Mobile Column Lazy Loading (Phases 76–79) — SHIPPED 2026-05-17</summary>

Full goals, success criteria, and notes: [milestones/v1.24-ROADMAP.md](milestones/v1.24-ROADMAP.md).

- [x] Phase 76: `portal_lazy.js` Coordinator (1/1 plan) — 2026-05-17
- [x] Phase 77: Gadget Partial Wiring + Tab Hook (1/1 plan) — 2026-05-17
- [x] Phase 78: Contract Tests + Cucumber E2E (1/1 plan) — 2026-05-17
- [x] Phase 79: Note Gadget AJAX Extraction (1/1 plan) — 2026-05-17

</details>

---

*Last updated: 2026-05-18 — milestone v1.25 roadmap*
