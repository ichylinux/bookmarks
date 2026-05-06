# Feature Landscape

**Domain:** Existing settings UX — device-aware font-size baseline (3-option UI retained)
**Researched:** 2026-05-06

## Must-Have Behavior (Table Stakes)

| Feature | Why Expected | Complexity | Notes |
|---|---|---:|---|
| Keep exactly 3 options: Small / Medium / Large | Existing UI contract already shipped | Low | Keep labels and order unchanged in ja/en (`small, medium, large`) |
| Store symbolic preference, not device-specific px | User expects one setting that follows account | Med | Persist `small|medium|large`; compute effective size per device at render time |
| Device-aware baseline for **Medium** | Core requirement | Med | Define Medium separately for desktop vs mobile; Small/Large are relative offsets from Medium |
| Relative sizing consistency | Predictable UX | Med | Enforce `small < medium < large` on each device class |
| One-time migration for safety: `nil` and `medium` → `small` | Avoid UX shock for existing users | Med | Migration should be idempotent and never rerun for already-migrated users |
| Backward-compatible rendering fallback | Existing code uses fallback today | Low | Invalid/missing values still render safely (fallback to Small after migration policy) |
| Cross-device deterministic behavior | Users switch PC/mobile | Med | Same stored option maps to device-appropriate effective size with no data rewrite on switch |
| Clear save feedback | Existing preferences UX pattern | Low | Reuse normal “Preferences saved” flow; no surprise hidden side effects |

## Optional Enhancements (Differentiators)

| Feature | Value Proposition | Complexity | Notes |
|---|---|---:|---|
| One-time in-app notice after migration | Reduces confusion (“why text changed?”) | Low | Short message: baseline changed; setting still controllable via same 3 options |
| Inline helper text under font-size select | Better mental model | Low | Example: “Medium adapts by device; Small/Large are relative” |
| Read-only effective-size hint in preferences | Transparency | Low/Med | e.g. “Current device effective size: Medium = Xpx” |

## Anti-Features (Do NOT Build)

| Anti-Feature | Why Avoid | What to Do Instead |
|---|---|---|
| Add 4th+ size options (XL, XS, custom slider) | Scope creep; breaks existing simple UX | Keep strict 3-option model |
| Device-specific user settings (desktop value + mobile value) | Increases cognitive load and QA matrix | Single stored option + device-aware mapping |
| Repeated auto-remapping on every sign-in/device change | Feels unstable and untrustworthy | One-time migration only (`nil/medium` to `small`) |
| Silent behavior change with no communication | User confusion/support burden | Add brief release note or one-time notice |
| Pixel-exact promises in UI copy | Fragile across themes/device classes | Communicate relative behavior, not absolute px guarantees |

## Edge Cases (Desktop/Mobile Switching)

1. **User has `small`, opens on desktop then mobile**  
   - Expectation: stays `small`; only effective px changes by device baseline.
2. **User migrated from legacy `medium` to `small`**  
   - Expectation: no repeated migration; user can manually reselect `medium`.
3. **User explicitly sets `medium` after release**  
   - Expectation: honor choice; never auto-downgrade again.
4. **Unknown/invalid stored value**  
   - Expectation: safe fallback class and no crash; prefer effective `small`.
5. **Theme switch (modern/classic/simple)**  
   - Expectation: font-size semantics consistent across themes.

## Feature Dependencies

```text
Device classification (desktop/mobile)
  → Medium baseline definition per class
    → Relative offsets for Small/Large
      → CSS/body class application
        → Migration safety + user communication
```

## MVP Recommendation

Prioritize:
1. One-time migration (`nil/medium` → `small`) with idempotency.
2. Device-aware Medium + relative Small/Large mapping.
3. Stable 3-option preferences UX (labels/order unchanged).
4. Edge-safe fallback behavior for invalid values.

Defer:
- Effective-size preview/hint UI and one-time migration notice (valuable, but optional if schedule tight).

## Acceptance Criteria Candidates

- Preferences page still shows exactly 3 options in both locales: Small/Medium/Large.
- Existing users with `font_size = nil` are migrated to `small`.
- Existing users with `font_size = medium` are migrated to `small`.
- Users already on `small` or `large` are unchanged by migration.
- Migration is idempotent (re-running causes no further changes).
- Stored preference remains symbolic (`small|medium|large`), not device-specific numeric values.
- On desktop and mobile, `medium` effective size differs per design baseline.
- On each device class: `small` renders smaller than `medium`; `large` renders larger than `medium`.
- Device switching does not rewrite stored preference.
- Manual post-release selection of `medium` is preserved.
- Invalid/missing values render with safe fallback behavior (no exception, predictable class).

## Sources

- `/app/views/preferences/index.html.erb` (3-option UI and medium default selection behavior)
- `/app/helpers/welcome_helper.rb` (body class fallback behavior)
- `/app/models/preference.rb` (allowed font-size values)
- `/config/locales/ja.yml`, `/config/locales/en.yml` (existing labels/localized UX contract)
- `/app/assets/stylesheets/common.css.scss` (current class-based size mapping)
- `/test/controllers/preferences_controller_test.rb`, `/test/models/preference_test.rb` (current behavior contracts)
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
