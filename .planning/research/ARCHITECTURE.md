# Architecture: Device-Aware Font-Size Baseline

**Domain:** Rails monolith typography preference integration  
**Researched:** 2026-05-06

## Integration Goal

Add device-aware baseline typography (PC/mobile split), keep user preference scaling (`small` / `large`) relative to baseline, and migrate legacy defaults (`nil` / `medium`) to `small` with minimal regressions.

---

## 1) Integration map (new vs modified)

### New components

| Component | Layer | Responsibility |
|---|---|---|
| `Preference#effective_font_size` | Model | Normalize stored value into active size token (temporary compatibility: map `nil`/`medium` to `small`) |
| Data migration (new migration file) | DB | Backfill `preferences.font_size`: `NULL` and `'medium'` → `'small'` |
| Optional migration to set DB default | DB | Set future default to `'small'` (if team wants non-null persistence contract) |

### Modified components

| File | Layer | Change |
|---|---|---|
| `app/models/preference.rb` | Model | Add explicit default (`FONT_SIZE_DEFAULT = small`), deprecate medium path, update validation strategy by phase |
| `app/helpers/welcome_helper.rb` | Helper | Replace direct fallback logic with `current_user.preference.effective_font_size`; keep body class contract stable |
| `app/views/layouts/application.html.erb` | View | Keep `font-size-*` body class pattern; optionally add `font-size-v2` marker class for rollout safety |
| `app/views/preferences/index.html.erb` | View | Default selected option becomes `small`; remove or deprecate `medium` option when migration complete |
| `app/assets/stylesheets/common.css.scss` | CSS contract | Introduce CSS custom properties for device baseline + user scale; `font-size-small/large` only set scale |
| `app/assets/stylesheets/themes/*.css.scss` | Theme CSS | Ensure theme rules do not hard-break root scaling; convert critical fixed text px to rem/em incrementally |
| `test/controllers/preferences_controller_test.rb` | Tests | Update body class fallback expectations and select-option expectations |
| `test/models/preference_test.rb` | Tests | Add `effective_font_size` behavior tests and deprecation compatibility tests |

---

## 2) Data migration touchpoints

## Phase-safe migration strategy

1. **Compatibility first** (app code):  
   - `effective_font_size` maps `nil` and `medium` to `small`.
   - UI default selection changes to `small`.
2. **Data backfill** (DB migration):  
   - `UPDATE preferences SET font_size = 'small' WHERE font_size IS NULL OR font_size = 'medium';`
3. **Contract tighten** (later phase):  
   - Remove `medium` from allowed values.
   - Optionally set `null: false` + default `'small'` in schema (only after clean backfill and test green).

This prevents runtime regressions during deploy windows where app and DB may be out of sync.

---

## 3) CSS contract approach (recommended)

Use one root contract in `common.css.scss`:

- `--font-base-pc` (medium baseline for desktop)
- `--font-base-mobile` (medium baseline for mobile)
- `--font-scale` (user preference multiplier)

Example contract shape:

- `body` font-size = `calc(var(--font-base-pc) * var(--font-scale))`
- mobile media query switches to `var(--font-base-mobile)`
- `body.font-size-small { --font-scale: ... }`
- `body.font-size-large { --font-scale: ... }`
- temporary: `body.font-size-medium` alias to small scale during migration window (or map in helper and stop outputting medium)

This keeps model/helper simple and pushes device logic to CSS where viewport truth exists.

---

## 4) Theme interaction notes

Current theme files contain many fixed `px` font sizes (`modern`, `classic`, `simple`).  
Implication: body/root scaling will not affect all text equally until those are migrated to rem/em.

Recommended theme policy:

- **Do now:** ensure shell typography follows root contract (body, wrapper, key nav text).
- **Do incrementally:** convert fixed px in theme-specific components to rem for consistent scaling.
- **Avoid now:** full typography rewrite in same milestone (high regression risk).

---

## 5) Test surface updates

Minimum regression net:

- `test/controllers/preferences_controller_test.rb`
  - fallback class expectation: nil -> `font-size-small` (not medium)
  - options shown in preferences (if medium removed, assert only small/large)
- `test/models/preference_test.rb`
  - `effective_font_size` maps nil/medium to small (during compatibility phase)
  - invalid values rejected
- Add/adjust integration assertion that `<body>` still includes theme + font-size class combination.

Recommended additions:

- CSS contract test (asset-level) asserting presence of `--font-base-pc`, `--font-base-mobile`, `--font-scale`.
- One per-theme smoke assertion to ensure no catastrophic readability regression in modern/classic/simple.

---

## 6) Build order (min-regression phase decomposition)

1. **Phase A — Compatibility seam (no behavior break)**
   - Add `effective_font_size`, helper delegation, keep current classes.
   - Add tests for normalization.
   - Rationale: creates safe abstraction before changing defaults/data.

2. **Phase B — CSS baseline v2**
   - Introduce device-aware CSS variables and scaling contract in `common.css.scss`.
   - Keep medium alias temporarily.
   - Rationale: ships core capability with backward compatibility.

3. **Phase C — Data migration + UI default shift**
   - Backfill `nil`/`medium` -> `small`.
   - Preferences form default and tests updated.
   - Rationale: align persisted data with new behavior after runtime supports both.

4. **Phase D — Cleanup/tighten**
   - Remove medium from model/UI/contracts.
   - Optional DB constraint tightening.
   - Rationale: only after production data and tests prove stable.

**Dependency rationale:** abstraction first → rendering contract → data rewrite → strictness.  
This sequencing avoids deploy-order bugs and limits user-visible regressions.

---

## Source files examined

- `.planning/PROJECT.md`
- `app/models/preference.rb`
- `app/helpers/welcome_helper.rb`
- `app/views/layouts/application.html.erb`
- `app/views/preferences/index.html.erb`
- `app/assets/stylesheets/common.css.scss`
- `app/assets/stylesheets/themes/modern.css.scss`
- `app/assets/stylesheets/themes/classic.css.scss`
- `app/assets/stylesheets/themes/simple.css.scss`
- `test/controllers/preferences_controller_test.rb`
- `test/models/preference_test.rb`
- `test/support/preferences.rb`
- `db/migrate/20260501000200_add_font_size_to_preferences.rb`
- `db/schema.rb`
