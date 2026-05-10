# Roadmap: Bookmarks

## Milestones

- ✅ **v1.1 — Modern JavaScript** — Phases 2–4 (shipped 2026-04-27) — [archived](milestones/v1.1-ROADMAP.md)
- ✅ **v1.2 — Modern Theme** — Phases 5–9 (shipped 2026-04-29) — [archived](milestones/v1.2-ROADMAP.md)
- ✅ **v1.3 — Quick Note Gadget** — Phases 10–13 (shipped 2026-04-30) — [archived](milestones/v1.3-ROADMAP.md)
- ✅ **v1.4 — Internationalization** — Phases 14–18.2 (shipped 2026-05-03) — [archived](milestones/v1.4-ROADMAP.md)
- ✅ **v1.5 — Verification Debt Cleanup** — Phases 19–22 (shipped 2026-05-04) — [archived](milestones/v1.5-ROADMAP.md)
- ✅ **v1.6 — Note Gadget for All Themes** — Phases 23–25 (shipped 2026-05-04) — [archived](milestones/v1.6-ROADMAP.md)
- ✅ **v1.7 — Mobile Portal Layout** — Phases 26–28 (shipped 2026-05-04)
- ✅ **v1.8 — Mobile UX Enhancement** — Phases 29–32.1 (shipped 2026-05-05) — [archived](milestones/v1.8-ROADMAP.md)
- ✅ **v1.9 — Mobile Regression Hardening** — Phases 33–33.2 (shipped 2026-05-05) — [archived](milestones/v1.9-ROADMAP.md)
- ⚠️ **v1.10 — HTTP Client Consolidation** — Phases 34–36 (deferred 2026-05-06)
- ✅ **v1.11 — Device-aware Font Size Baseline** — Phases 37–39 (shipped 2026-05-06) — [archived](milestones/v1.11-ROADMAP.md)
- ✅ **v1.12 — Landing Page for User Acquisition (Phase 1)** — Phases 40–42 (shipped 2026-05-08) — [archived](milestones/v1.12-ROADMAP.md)
- ✅ **v1.13 — Root Entry Redirect to Landing for Guests** — Phases 43–45 (shipped 2026-05-08) — [archived](milestones/v1.13-ROADMAP.md)
- ✅ **v1.14 — Landing Page Changelog** — Phases 46–48 (shipped 2026-05-10) — [archived](milestones/v1.14-ROADMAP.md)
- ✅ **v1.15 — CSS & UI Polish** — Phases 49–51 (shipped 2026-05-11)

## Phases

### v1.15 — CSS & UI Polish

---

#### Phase 49: CSS Architecture Audit & Migration

**Goal:** Audit all non-theme SCSS files for misplaced theme-specific selectors and migrate violations to the correct theme files.

**Requirements:** ARCH-01, ARCH-02, ARCH-03

**Success criteria:**
1. Every `.css.scss` file outside `themes/` is inspected for `.modern`, `.classic`, `.simple` prefixed selectors
2. All violations moved to the correct `themes/modern.css.scss`, `themes/classic.css.scss`, or `themes/simple.css.scss`
3. Un-prefixed base styles remain in their source file
4. Tri-suite green after migration

---

#### Phase 50: Visual QA & Cross-theme Consistency Fixes

**Goal:** Verify the preferences page and shared components visually across all 3 themes; fix any inconsistencies found.

**Requirements:** PREFS-01, PREFS-02, PREFS-03, CONS-01, CONS-02, CONS-03

**Success criteria:**
1. Preferences page inspected and correct on modern, classic, and simple themes
2. Form controls, action links, and flash/notice messages render consistently across themes
3. Any visual inconsistencies found during QA are fixed
4. Tri-suite green

---

#### Phase 51: Mobile/Responsive Polish & Verification Gate

**Goal:** Fix mobile layout issues on key pages; final tri-suite gate for v1.15.

**Requirements:** MOB-01, MOB-02 (+ all v1.15 requirements verified)

**Plans:** 1 plan

Plans:
- [x] 051-01-PLAN.md — Add mobile CSS for preferences + bookmarks tables; structural Minitest assertions; tri-suite gate (2026-05-11)

**Success criteria:**
1. Welcome, preferences, and bookmarks list render usably at ≤767px on all 3 themes
2. No layout overflow or broken stacking on narrow viewports
3. All ARCH / PREFS / CONS / MOB requirements verified
4. Tri-suite (lint + Minitest + Cucumber) green — v1.15 ready to ship

---

*Last updated: 2026-05-11 — v1.15 CSS & UI Polish shipped (Phases 49–51 complete).*
