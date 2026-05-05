# Feature Landscape — v1.8 Mobile UX Enhancement

**Domain:** Mobile column-switch UX (Welcome/Portal)  
**Researched:** 2026-05-05

## Table Stakes

If these are missing, users lose context ("where was I last time?") and perceive interactions as heavy; the mobile UX feels incomplete.

| Feature | Why Expected (user behavior) | Complexity | Notes |
|---------|------------------------------|------------|-------|
| Left/right swipe column switch | One-handed users prefer swiping content directly over precise tab targeting | Medium | Reuse the same active-index state as tab switching; avoid dual logic paths |
| Persist/restore last viewed column (`localStorage`) | Users expect revisit/back navigation to preserve context; resetting to column 1 increases drop-off | Low | Treat `ENH-02` as mandatory in v1.8; key naming should be theme-agnostic and user-aware |
| False-trigger suppression for swipe (threshold + direction) | False horizontal detection during vertical scroll causes high frustration | Medium | Use horizontal distance/speed/angle rules with vertical-scroll priority |
| Consistency with tab UI | Mixed swipe/tap usage still requires one consistent visible state | Low | Immediately sync tab active state after swipe transitions |

## Differentiators

These are clearly valuable but not mandatory for the first MVP cut.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Minimal transition animation tuning | Increases confidence by making column transitions easier to perceive | Medium | Respect `prefers-reduced-motion`; keep transitions short |
| Boundary feedback at first/last column | Makes "can't go further" immediately understandable and reduces retry noise | Medium | Lower learning cost than silent no-op behavior |
| Limited ENH-01 label enhancement | Improves discoverability vs number-only tabs | Medium | Prefer metadata-derived labels first, not full user-edit UI |

## Anti-Features

Items likely to cause schedule overrun or quality degradation if included now.

| Anti-Feature | Why Avoid | What to Do Instead |
|--------------|-----------|-------------------|
| Full mobile D&D reorder implementation (full ENH-03) | Touch conflicts (scroll/swipe/drag) greatly expand bug surface | In v1.8, limit to investigation + acceptance criteria; defer implementation to a separate phase |
| Column state persistence with URL/server sync in same step | Over-scoped relative to `localStorage` requirement and needs separate sync design | Restrict v1.8 to local-device restore only |
| Redesigning column structure itself (column-count/layout overhaul) | Drifts away from milestone goal (intuitive switch + restore) | Keep existing `portal_column_count` and theme structure |

## User Behavior Contracts

1. When users open the Welcome page, show the saved column if available; otherwise default to column 1.  
2. Swiping left/right across the column area changes column only when the gesture crosses threshold.  
3. Whether users move by tab tap or swipe, the final active column is written using the same `localStorage` path.  
4. During primarily vertical scroll interactions, column switching never fires.  
5. At first/last column boundaries, additional outward swipes do not change active state.  

## Deferred Items Re-evaluation (ENH-01 / ENH-03)

### ENH-01: User-configurable tab labels per column

**Go conditions for inclusion in v1.8**
- Delivery buffer remains after swipe + persistence implementation and verification.  
- Scope is limited to display-name improvements from existing metadata (not full edit UI).  
- Works under existing modern/classic/simple DOM contract without breaking shared selectors.  

**No-go conditions (defer)**
- Requires new persistence destination for labels (DB/schema changes).  
- i18n-key or settings-UI expansion materially delays v1.8 core goals.  

### ENH-03: Drag-and-drop gadget reorder on mobile

**Go conditions for inclusion in v1.8**
- Gesture-priority design is finalized to avoid conflict with swipe interactions.  
- Existing desktop sortable logic can be reused safely with minimal mobile-only branching.  
- Stable E2E coverage can be established for mobile reorder behavior.  

**No-go conditions (defer)**
- Touch interactions show frequent scroll/swipe/drag conflicts and high misfire rate.  
- Cucumber scenarios cannot reproduce behavior reliably, weakening regression detection.  
- It delays v1.8 completion criteria (intuitive switching + revisit restore).  

## MVP Recommendation (v1.8)

Prioritize:
1. Swipe-based column switching (with false-trigger suppression)
2. `localStorage` persistence and restore of active column
3. Finalized Go/No-Go criteria for ENH-01 and ENH-03 (implementation only if criteria are met)

Defer:
- ENH-03 implementation body: high gesture-conflict risk; better isolated to a later phase.
- Full ENH-01 user-edit UI: over-scoped for v1.8.

## Sources

- `/home/ichy/workspace/bookmarks/.planning/PROJECT.md` (v1.8 goal, active requirements, constraints)
- `/home/ichy/workspace/bookmarks/.planning/REQUIREMENTS.md` (v1.7 delivered baseline, ENH-01/02/03 definitions)
