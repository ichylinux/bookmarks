---
phase: 21
slug: phase-06-verification-closure
status: approved
shadcn_initialized: false
preset: none
created: 2026-05-03
reviewed_at: 2026-05-03T00:00:00Z
---

# Phase 21 — UI Design Contract

> Visual and interaction contract for **verification closure only** (no new feature scope).  
> Scope locked to Phase 06 claim verification (`NAV-01`, `NAV-02`, and non-modern unaffected behavior) per `21-CONTEXT.md`.

---

## Design System

| Property | Value |
|----------|-------|
| Tool | none (existing Rails + Sprockets UI) |
| Preset | not applicable |
| Component library | none |
| Icon library | none (existing app assets only) |
| Font | `-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif` |

---

## Scope Lock (Verification-Only)

1. Use exactly **3 claims** in Phase 21 verification evidence:
   - `NAV-01` modern header hamburger presence
   - `NAV-02` drawer/nav behavior contract
   - non-modern unaffected contract claim
2. Non-modern claim must cover **both** `classic` and `simple`.
3. Non-modern claim must explicitly map to `NAV-01` + `NAV-02` and Phase 6 criterion 4 anchor (`.planning/milestones/v1.2-ROADMAP.md`).
4. Evidence strictness is interaction-level plus structural checks; no manual-only closure.

---

## Interaction Contract (Evidence Targets)

| Contract ID | Theme/Context | Required Behavior | Evidence Anchor |
|-------------|---------------|-------------------|-----------------|
| IC-01 | `modern` + signed-in | `button.hamburger-btn` exists in header; drawer/overlay exist as `body` direct children; click hamburger toggles `body.drawer-open`; overlay/Esc/drawer-link close drawer | `app/views/layouts/application.html.erb`, `app/assets/javascripts/menu.js`, `test/controllers/welcome_controller/layout_structure_test.rb`, `features/03.モダンテーマ.feature` |
| IC-02 | `classic` + signed-in | Hamburger + drawer + overlay remain present and interactive (non-modern still supports drawer path) | `welcome_helper.rb#drawer_ui?`, `menu.js` guard for `body.classic`, layout structure test (`クラシックテーマ...`) |
| IC-03 | `simple` + signed-in | No hamburger/drawer/overlay; simple menu (`ul.navigation`) remains active; drawer JS must not attach side effects | layout structure test (`シンプルテーマ...`), `drawer_ui?` false for simple, `menu.js` early return when not `modern/classic` |
| IC-04 | Non-modern unaffected claim | Evidence must show no regression in classic/simple behavior while modern contracts are verified | Phase 21 verification claim mapping + Phase 6 criterion 4 reference |

---

## Spacing Scale

Declared values (multiples of 4 only):

| Token | Value | Usage |
|-------|-------|-------|
| xs | 4px | Micro gaps, inline icon spacing |
| sm | 8px | Tight control spacing |
| md | 16px | Default content spacing |
| lg | 24px | Section spacing |
| xl | 32px | Large section spacing |
| 2xl | 48px | Major visual break |
| 3xl | 64px | Page-level separation |

Verification artifacts should use these values when adding any new evidence-oriented UI text blocks or callouts.

---

## Typography

| Role | Size | Weight | Line Height |
|------|------|--------|-------------|
| Body | 16px | 400 | 1.5 |
| Label | 14px | 400 | 1.4 |
| Heading | 20px | 600 | 1.2 |
| Display | 28px | 600 | 1.2 |

---

## Color

| Role | Value | Usage |
|------|-------|-------|
| Dominant (60%) | `#FFFFFF` | Page background and primary surfaces |
| Secondary (30%) | `#1E40AF` | Header/nav surface context |
| Accent (10%) | `#3B82F6` | Verification-action emphasis and focus-visible outlines |
| Destructive | `#DC2626` | FAIL/destructive state only |

Accent is reserved for:
- primary verification action emphasis,
- focus-visible outlines,
- claim status emphasis requiring maintainer attention.

Not reserved for general body text.

---

## Visual Priority

1. Claim-level PASS/FAIL evidence status visibility
2. Interaction/structure proof links for each claim
3. Policy notes (fail-first, minimal-fix, one-rerun logging)

---

## Copywriting Contract

| Element | Copy |
|---------|------|
| Primary CTA | Record Phase 06 Verification Evidence |
| Empty state heading | No Phase 06 verification evidence recorded |
| Empty state body | Add evidence entries for `NAV-01`, `NAV-02`, and non-modern unaffected behavior (classic + simple), then run `yarn run lint && bin/rails test && bundle exec rake dad:test`. |
| Error state | Verification run failed. Record FAIL with evidence first, then apply only claim-coupled minimal fixes and re-verify affected claims. |
| Destructive confirmation | Mark claim as FAIL: “Mark this Phase 06 claim as FAIL and attach evidence now?” |

---

## Registry Safety

| Registry | Blocks Used | Safety Gate |
|----------|-------------|-------------|
| shadcn official | none | not required |
| third-party | none | not applicable |

---

## Checker Sign-Off

- [ ] Dimension 1 Copywriting: PASS
- [ ] Dimension 2 Visuals: PASS
- [ ] Dimension 3 Color: PASS
- [ ] Dimension 4 Typography: PASS
- [ ] Dimension 5 Spacing: PASS
- [ ] Dimension 6 Registry Safety: PASS

**Approval:** pending
