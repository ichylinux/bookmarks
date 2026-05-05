# Technology Stack

**Project:** Bookmarks  
**Milestone:** v1.8 Mobile UX Enhancement  
**Researched:** 2026-05-05

## Recommended Stack (Minimal Change)

Keep the existing `Rails + Sprockets + jQuery` stack and implement mobile UX behavior with first-party JavaScript. Do not introduce a new frontend framework or bundler migration in this milestone.

### Core

| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| Rails | 8.1.x | SSR screens and existing controller/view assets | Reuses current operations and test assets with minimal risk |
| Sprockets | current | JS/CSS delivery | Matches current pipeline and milestone constraints |
| jQuery (`jquery-rails`) | 4.6.1 | DOM operations and event support | High consistency with existing code style |

### Implementation Policy (v1.8)

1. **Swipe-based column switching**  
   - Use `Pointer Events` first, with `touch*` fallback only when necessary.  
   - A lightweight utility with horizontal threshold + vertical-noise filtering is sufficient.
2. **Persist selected column**  
   - Use `localStorage` through the `Storage` API (`getItem/setItem/removeItem`).  
   - Validate availability first and fall back to non-persistent in-memory behavior on failure.
3. **Deferred-item reassessment**  
   - For label improvements and reorder ideas, evaluate feasibility with existing JS/CSS first; dependency addition is a last resort.

## Additional Libraries

### Recommended

- **No additional library (default)**  
  Rationale: swipe and persistence are implementable with browser-standard APIs and avoid dependency/maintenance overhead.

### Conditional Allowance (Usually Unnecessary)

- If a tiny utility is introduced, limit to one package and require full compatibility with Sprockets and existing ESLint conventions.

## Non-Recommended (今回非推奨)

| Option | Why Not |
|--------|---------|
| New frontend framework (including React/Vue/Stimulus migration) | Violates milestone constraints and adds unnecessary migration cost |
| jQuery Mobile introduction | Officially end-of-life; high future maintenance risk |
| Premature gesture-library adoption (for example Hammer.js) | Over-scoped for left/right swipe + persistence requirements |
| Simultaneous migration to Webpack/Vite/esbuild | Out of scope and increases delivery risk |

## Compatibility Risks (Must Be Explicit During Implementation)

### 1) Sprockets

- **Risk:** Event initialization can break when file load order changes.  
- **Mitigation:** Keep manifest order deterministic and follow the existing non-Turbolinks initialization pattern used in `application.js`.

### 2) jQuery

- **Risk:** jQuery does not provide high-level swipe events; misusing `touchmove`/`pointermove` can interfere with scrolling.  
- **Mitigation:** Handle raw events explicitly with vertical-scroll-priority logic; keep jQuery limited to DOM selection/binding support.

### 3) Touch / Pointer Events

- **Risk:** Incorrect `preventDefault()` / passive listener usage can break intended gesture control.  
- **Mitigation:** Set `touch-action` intentionally and use non-passive listeners only where required.  
- **Risk:** Pointer/Touch API behavior differs by environment.  
- **Mitigation:** Use Pointer-first with Touch fallback and shared threshold logic to absorb differences.

### 4) localStorage

- **Risk:** `setItem` can throw in private mode or quota-limited environments.  
- **Mitigation:** Use availability checks and try/catch; continue safely with default column behavior on failure.

## Practical Recommendation for v1.8

- **Adopt:** Keep existing stack + implement swipe/localStorage in first-party code  
- **Why:** Best fit for constraints, lowest risk, fastest path to user value  
- **Acceptance gate:** All three suites green (`yarn run lint` / `bin/rails test` / `bundle exec rake dad:test`)

## Sources

- MDN: Pointer Events (Using Pointer Events) — https://developer.mozilla.org/en-US/docs/Web/API/Pointer_events/Using_Pointer_Events  
- MDN: Web Storage API (Using the Web Storage API) — https://developer.mozilla.org/en-US/docs/Web/API/Web_Storage_API/Using_the_Web_Storage_API  
- jQuery API documentation — https://api.jquery.com/  
- jQuery Mobile swipe docs (support ended notice) — https://api.jquerymobile.com/swipe/
