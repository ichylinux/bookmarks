---
phase: 20
slug: phase-05-verification-closure
status: approved
shadcn_initialized: false
preset: none
created: 2026-05-03
reviewed_at: 2026-05-03T19:21:40+09:00
---

# Phase 20 — UI Design Contract

> Visual and interaction contract for **verification closure only** (no new feature scope).  
> Scope locked to Phase 05 claim verification (`THEME-01..03`) per `20-CONTEXT.md`.

---

## Design System

| Property | Value |
|----------|-------|
| Tool | none (Rails + Sprockets existing UI) |
| Preset | not applicable |
| Component library | none |
| Icon library | none (existing app assets only) |
| Font | `-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif` |

---

## Spacing Scale

Declared values (must be multiples of 4):

| Token | Value | Usage |
|-------|-------|-------|
| xs | 4px | Micro gaps, inline icon spacing |
| sm | 8px | Tight control spacing |
| md | 16px | Default content spacing |
| lg | 24px | Section spacing |
| xl | 32px | Large section spacing |
| 2xl | 48px | Major visual break |
| 3xl | 64px | Page-level separation |

Legacy non-token spacing may exist in historical CSS, but this contract introduces and validates only the standard spacing tokens above.

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
| Secondary (30%) | `#1E40AF` | Modern header/nav surface |
| Accent (10%) | `#3B82F6` | Focus outlines, actionable link/button emphasis |
| Destructive | `#DC2626` | FAIL/destructive status only |

Accent reserved for: focus-visible outlines, actionable control emphasis in modern theme, and verification-status highlight (not general body text).

---

## Visual Priority

Primary focal point is the verification-closure action area (claim status/evidence capture), followed by claim-level PASS/FAIL state visibility, then supporting policy/help text.

---

## Copywriting Contract

| Element | Copy |
|---------|------|
| Primary CTA | Record Verification Evidence |
| Empty state heading | No Phase 05 verification evidence recorded |
| Empty state body | Add claim entries for THEME-01, THEME-02, and THEME-03, then run `yarn run lint && bin/rails test && bundle exec rake dad:test`. |
| Error state | Verification run failed. Record FAIL with evidence first, then apply minimal fix only if claim-coupled and re-run affected checks. |
| Destructive confirmation | Mark claim as FAIL: “Mark this claim as FAIL and attach artifact evidence now?” |

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
