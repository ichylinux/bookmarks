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
- ✅ **v1.13 — Root Entry Redirect to Landing for Guests** — Phases 43–45 (shipped 2026-05-08)

## Phases

### Phase 43 — Guest Entry Routing Foundation

**Goal:** Route unauthenticated users from `/` to `/landing` while preserving authenticated `/` dashboard behavior.

**Requirements:** ENTRY-02, ENTRY-03, ENTRY-04

**Success Criteria:**
1. Unauthenticated requests to `/` redirect to `/landing`.
2. Authenticated requests to `/` still render the existing dashboard and gadgets.
3. `/landing` remains directly accessible for unauthenticated visitors.

### Phase 44 — Conversion and Locale Guardrails

**Goal:** Keep conversion CTA visibility and locale-safe rendering intact after guest entry routing changes.

**Requirements:** LAND-04, COMP-03

**Success Criteria:**
1. `/landing` still exposes clear login/sign-up CTAs after root redirect changes.
2. Entry routing behavior remains correct under ja/en locale contexts.
3. Auth entry and landing messaging stay consistent with existing localized tone.

### Phase 45 — Entry Routing Verification Gate

**Goal:** Lock guest-entry routing and locale-aware landing behavior with automated regression coverage.

**Requirements:** TEST-04, TEST-05

**Success Criteria:**
1. Automated tests assert auth-state-aware root behavior (guest redirect, signed-in dashboard).
2. Tests assert `/landing` rendering and CTA contracts under ja/en contexts.
3. Regression suite fails on accidental changes to entry routing or landing CTAs.

---
*Last updated: 2026-05-08 — v1.13 shipped.*
