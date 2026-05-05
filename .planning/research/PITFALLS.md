# Domain Pitfalls — v1.8 Mobile UX Enhancement

**Domain:** Mobile column switching (swipe) and `localStorage` persistence  
**Researched:** 2026-05-05

## Critical Pitfalls

### Pitfall 1: False swipe switching changes columns unintentionally
**What goes wrong:** Vertical scroll or light touch movement is misdetected as horizontal swipe, causing unwanted column changes.  
**Why it happens:** Detection relies on raw delta only, with weak threshold/direction-lock/velocity checks.  
**Consequences:** Higher interaction frustration, loss of context, and wrong column being persisted for revisit.  
**Prevention:**  
- Switch only when horizontal dominance (`abs(dx) > abs(dy)`) and minimum distance are both satisfied.  
- Lock direction after swipe start; cancel when gesture returns to vertical intent.  
- Add cooldown and enforce one-switch-per-gesture.  
**Detection:** Validate false-switch rate during vertical scroll in manual mobile checks, and add E2E scenarios for "no switch on vertical movement."

### Pitfall 2: スクロール競合で操作不能になる
**What goes wrong:** Vertical page scroll and swipe handling conflict, causing scroll lock or jitter.  
**Why it happens:** Poor `touch-action` usage and excessive `preventDefault()` block native browser gestures.  
**Consequences:** Lower usability, degraded perceived performance, and OS/browser-specific regressions.  
**Prevention:**  
- Scope `touch-action` to column containers only; avoid global `none`.  
- Call `preventDefault()` only for active swipe gestures and keep normal vertical scrolling native.  
- Verify behavior on real devices (iOS Safari / Android Chrome).  
**Detection:** Reproduce frame drops/scroll lock on devices; keep CI focused on class-state transitions and include device checks in acceptance criteria.

### Pitfall 3: Accessibility regression (swipe becomes required)
**What goes wrong:** Users who cannot swipe lose the ability to switch columns.  
**Why it happens:** Path-based gesture interaction is introduced without maintaining tab/button alternatives.  
**Consequences:** WCAG 2.5.1 (Pointer Gestures) risk and real user lockout.  
**Prevention:**  
- Keep existing tab switching always available; treat swipe as an enhancement, not a requirement.  
- Ensure switch UI remains focusable and operable via keyboard/assistive technology.  
- Avoid blanket `touch-action: none` that can interfere with expected interactions.  
**Detection:** Validate keyboard and screen-reader operability, and add accessibility-focused regression checks.

### Pitfall 4: `localStorage` inconsistency (invalid or stale values)
**What goes wrong:** Invalid saved data (out-of-range, non-numeric, stale key format) breaks restore or applies incorrect state.  
**Why it happens:** Weak validation, weak key strategy (no version/context separation), and missing exception handling.  
**Consequences:** Broken initial view, hidden-column bugs, and unexpected column on revisit.  
**Prevention:**  
- Apply strict validation on load (`1..portal_column_count`) and fall back safely to column 1 on failure.  
- Namespace keys (for example `bookmarks:v1.8:mobile:activeColumn`) with version tagging for forward compatibility.  
- Handle `SecurityError` and similar exceptions explicitly; continue operation without persistence when storage is unavailable.  
**Detection:** Cover invalid/missing/unavailable storage in tests, and validate restore behavior with manual DevTools bad-value injection.

## Moderate Pitfalls

### Pitfall 1: State leakage across layout modes
**What goes wrong:** Mobile-saved column state leaks into desktop rendering, or vice versa.  
**Prevention:** Gate restore behavior to mobile conditions and ignore saved values outside the mobile breakpoint.

### Pitfall 2: Missing DOM differences across themes
**What goes wrong:** Binding targets differ among modern/classic/simple, so only some themes work.  
**Prevention:** Define common selector contracts first and keep three-theme regression coverage mandatory.

## Minor Pitfalls

### Pitfall 1: Over-animated transitions causing discomfort/perceived lag
**What goes wrong:** Long transition effects make column switching feel slow or uncomfortable.  
**Prevention:** Keep transitions short and respect `prefers-reduced-motion`.

## Phase-Specific Warnings

| Phase Topic | Likely Pitfall | Mitigation |
|-------------|---------------|------------|
| v1.8 Phase A: Gesture specification | Ambiguous thresholds cause frequent false swipes | Define direction lock, min distance, and one-switch-per-gesture rules |
| v1.8 Phase B: Swipe implementation | Scroll conflicts and browser variance | Apply `touch-action` locally and require real-device checks |
| v1.8 Phase C: Persistence implementation | Invalid-value restore and key collisions | Add validation, fallback, and namespaced keys |
| v1.8 Phase D: A11y/regression checks | Swipe-only behavior blocks users | Keep tab/button alternatives and include keyboard verification |
| v1.8 Phase E: Pre-release verification | Flake misclassification hides regressions | Use tri-suite gate + `dad:test` rerun policy |

## Sources

- MDN: [`touch-action`](https://developer.mozilla.org/en-US/docs/Web/CSS/touch-action)（スクロール競合とジェスチャー制御） — HIGH  
- MDN: [`Window.localStorage`](https://developer.mozilla.org/en-US/docs/Web/API/Window/localStorage)（例外条件・保存特性） — HIGH  
- W3C WAI: [WCAG 2.2 SC 2.5.1 Pointer Gestures](https://www.w3.org/WAI/WCAG22/Understanding/pointer-gestures.html)（スワイプ代替操作要件） — HIGH
