# Domain Pitfalls

**Domain:** Device-aware typography + persisted font-size migration
**Researched:** 2026-05-06

## Critical Pitfalls

### Pitfall 1: Semantic drift between DB values and render fallback
**What goes wrong:** `nil`/`medium` are migrated to `small`, but runtime still treats fallback/default as `medium`.  
**Why it happens:** Current helper/view hardcode medium fallback (`font_size_class`, preferences select `selected:`).  
**Consequences:** Existing users see unexpected size flips or inconsistent size between pages/settings.  
**Prevention (Phase 1: Semantics Contract):**
- Define one canonical mapping table (`nil -> small`, `medium -> small`, `small -> small`, `large -> large`).
- Apply mapping in one shared method (model/helper), not duplicated literals.
- Replace all render-time medium fallbacks with canonical default.
**Detection (testable warning signs):**
- Any `font-size-medium` fallback remains in helper/view.
- Any test still expects `body.font-size-medium` for nil.
- `grep` still finds `FONT_SIZE_MEDIUM` in fallback logic.

---

### Pitfall 2: Removing `medium` from validation/options before data migration
**What goes wrong:** Existing rows with `font_size='medium'` become invalid before backfill.  
**Why it happens:** Validation/constants/UI are changed before DB data is normalized.  
**Consequences:** `save!` paths in `PreferencesController` can raise and 500 on unrelated preference updates.  
**Prevention (Phase 2: Data Migration First):**
- Run data migration first: normalize `nil` and `medium` to `small`.
- Make migration idempotent and reversible strategy explicit.
- Only after migration, deprecate/remove `medium` from options/validation.
**Detection:**
- Pre-deploy SQL count of `font_size IS NULL OR font_size='medium'` is non-zero.
- Controller tests for preferences update fail with exceptions after constants change.

---

### Pitfall 3: CSS baseline conflict (global body class vs theme typography)
**What goes wrong:** Device-aware baseline and font-size classes compete with theme rules (`.modern { font-size: 16px; }`, global body px sizing).  
**Why it happens:** Mixed typography sources across `common.css.scss` and theme SCSS, mostly absolute px.  
**Consequences:** Different themes/devices render different effective sizes; “same preference” != same perceived size.  
**Prevention (Phase 3: CSS Integration):**
- Decide precedence explicitly: preference class should win over theme baseline (or vice versa).
- Add contract tests on compiled CSS precedence (not just string includes).
- Audit and reduce hardcoded px for key text surfaces impacted by body size.
**Detection:**
- Visual mismatch across `modern/classic/simple` with same preference.
- Tests only check source contains `16px`, not computed precedence with `body.font-size-*`.

---

### Pitfall 4: UI and i18n lag behind semantic change
**What goes wrong:** UI still exposes/translates “medium” though semantics changed to device-aware baseline.  
**Why it happens:** Locale files and preference form aren’t updated in lockstep with model constants.  
**Consequences:** User confusion; saved value doesn’t match displayed meaning.  
**Prevention (Phase 4: UI/I18n Cleanup):**
- Update `Preference::FONT_SIZES` and form options together.
- Update `ja/en` labels to new semantics.
- Add integration tests for option list and selected default.
**Detection:**
- Preferences page still renders `option[value='medium']`.
- Locale keys still include obsolete medium label without mapped meaning.

## Moderate Pitfalls

### Pitfall 1: No helper-level unit tests for fallback semantics
**What goes wrong:** Behavior changes silently because only controller/assert_select coverage exists.  
**Prevention (Phase 5: Test Hardening):**
- Add helper tests for signed-out, missing preference, nil value, legacy value mapping.
- Add regression test for canonical mapping method.

### Pitfall 2: One-shot migration without rollout guardrails
**What goes wrong:** Unexpected edge cases in production (stale values/manual edits) break assumptions.  
**Prevention (Phase 5: Rollout Safety):**
- Add temporary runtime guard: unknown values map to safe default.
- Add post-deploy query checks and alert threshold.

## Minor Pitfalls

### Pitfall 1: Existing users get changed silently without communication
**What goes wrong:** “Text suddenly changed” perception becomes support noise.  
**Prevention (Phase 4/5):**
- Add short release note/in-app notice: baseline updated, where to adjust size.

## Concrete Warning Signs (Checklist for planning/review)

- [ ] `app/helpers/welcome_helper.rb` still returns `'font-size-medium'` fallback.
- [ ] `app/views/preferences/index.html.erb` still defaults nil selection to `medium`.
- [ ] `Preference::FONT_SIZES` changed before DB backfill merged/deployed.
- [ ] Tests still assert `body.font-size-medium` for nil.
- [ ] Preferences option list still includes medium after migration policy finalization.
- [ ] No SQL verification step for remaining `nil/medium` rows.
- [ ] No cross-theme visual verification for same font preference on mobile/desktop.

## Phase-Specific Warnings

| Phase Topic | Likely Pitfall | Mitigation |
|-------------|---------------|------------|
| Phase 1: Semantics contract | Split source-of-truth for default mapping | Create one canonical mapper and reference it from helper/view/tests |
| Phase 2: Data migration | Validation/UI changed before data normalized | Deploy DB normalization first, confirm zero legacy rows, then tighten constants |
| Phase 3: CSS/device-aware baseline | Theme/global rule conflicts hide intended size | Define precedence and add compiled CSS + integration checks for body class outcome |
| Phase 4: UI/i18n update | Old option labels/values remain | Update form options + locale keys + option-render tests in same PR |
| Phase 5: Verification/rollout | Gaps in helper and migration observability | Add helper tests, migration assertions, and post-deploy DB checks |

## Sources

- `.planning/PROJECT.md` (constraints/decisions)
- `app/models/preference.rb`
- `app/helpers/welcome_helper.rb`
- `app/views/preferences/index.html.erb`
- `app/controllers/preferences_controller.rb`
- `app/assets/stylesheets/common.css.scss`
- `app/assets/stylesheets/themes/modern.css.scss`
- `test/models/preference_test.rb`
- `test/controllers/preferences_controller_test.rb`
- `test/assets/modern_full_page_theme_contract_test.rb`
- `.planning/quick/260501-q05-font-size-preference/260501-q05-PLAN.md`
- `.planning/quick/260501-q05-font-size-preference/260501-q05-SUMMARY.md`
