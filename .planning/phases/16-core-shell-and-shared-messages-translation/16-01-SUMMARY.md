---
phase: 16-core-shell-and-shared-messages-translation
plan: 01
subsystem: i18n
tags: [i18n, rails, locale-catalog]

requires:
  - phase: 15-language-preference
    provides: persisted locale preference and translated preferences page
provides:
  - top-level nav.* translation catalog in ja/en
  - shared flash.errors.generic translation in ja/en
  - ja/en locale key parity test
  - rails-i18n validation-message smoke test
affects: [phase-16, phase-17, phase-18, translation-coverage]

tech-stack:
  added: []
  patterns:
    - top-level absolute translation keys for shared chrome strings
    - YAML key parity test for ja/en locale files
    - rails-i18n smoke test for validation defaults

key-files:
  created:
    - test/i18n/locales_parity_test.rb
    - test/i18n/rails_i18n_smoke_test.rb
  modified:
    - config/locales/ja.yml
    - config/locales/en.yml

key-decisions:
  - "Kept nav.note as 'Note' in both locales per native-brand guidance."
  - "Did not add app-side errors.messages overrides; validation text remains delegated to rails-i18n."
  - "Filled missing English ActiveRecord attribute labels discovered by the parity gate so ja.yml and en.yml key sets match."

patterns-established:
  - "Shared shell strings live under top-level nav.* absolute keys."
  - "Shared generic error fallback lives under flash.errors.generic."
  - "Locale key symmetry is enforced by test/i18n/locales_parity_test.rb."

requirements-completed: [TRN-01, TRN-04]

duration: 4 min
completed: 2026-05-01
---

# Phase 16 Plan 01: Locale Catalog Foundation Summary

**Shared shell and flash translation catalog with ja/en parity enforcement and rails-i18n validation-default verification**

## Performance

- **Duration:** 4 min
- **Started:** 2026-05-01T07:03:25Z
- **Completed:** 2026-05-01T07:07:35Z
- **Tasks:** 4 completed
- **Files modified:** 4

## Accomplishments

- Added `nav.*` and `flash.errors.generic` to `config/locales/ja.yml` and `config/locales/en.yml`.
- Added `test/i18n/locales_parity_test.rb` to enforce identical ja/en key sets.
- Added `test/i18n/rails_i18n_smoke_test.rb` to confirm rails-i18n provides `errors.messages.blank` in both locales.
- Confirmed no app-side `errors.messages.*` or `activerecord.errors.messages.*` overrides were introduced.

## Task Commits

Each task was committed atomically:

1. **Task 1: Add nav.* and flash.errors.generic to ja.yml** - `8d174f2` (feat)
2. **Task 2: Mirror nav.* and flash.errors.generic into en.yml** - `f3aba1a` (feat)
3. **Task 3: Create locale key parity gate** - `ae186ac` (test)
4. **Task 4: Create rails-i18n smoke test** - `f153981` (test)

**Plan metadata:** this summary commit.

## Files Created/Modified

- `config/locales/ja.yml` - Added Japanese shared shell navigation and generic flash error keys.
- `config/locales/en.yml` - Added English shared shell navigation, generic flash error, and missing ActiveRecord attribute label keys needed for parity.
- `test/i18n/locales_parity_test.rb` - Compares flattened ja/en locale keys and reports asymmetric keys.
- `test/i18n/rails_i18n_smoke_test.rb` - Verifies rails-i18n resolves Japanese and English blank validation messages.

## Decisions Made

- Followed the planned top-level absolute key pattern: `nav.*` and `flash.errors.generic`.
- Preserved `Note` as a native-brand label in both locales.
- Kept rails-i18n as the source for validation message bodies instead of adding app-side `errors.*` translations.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Existing en.yml key asymmetry blocked the parity gate**

- **Found during:** Task 3 (locale key parity gate)
- **Issue:** The new full-key parity test failed because `ja.yml` already had `activerecord.attributes.{bookmark,calendar,feed,todo}` keys that `en.yml` lacked.
- **Fix:** Added English labels for those existing ActiveRecord attributes in `config/locales/en.yml`.
- **Files modified:** `config/locales/en.yml`
- **Verification:** `bin/rails test test/i18n/locales_parity_test.rb` passed with `1 runs, 4 assertions, 0 failures, 0 errors`.
- **Committed in:** `ae186ac`

---

**Total deviations:** 1 auto-fixed (1 blocking).  
**Impact on plan:** The fix directly supports Phase 16 success criterion 4 and TRN-04 validation-facing labels. No scope creep into feature views or controller substitutions.

## Issues Encountered

- `bundle exec rake dad:test` did not produce a green run after the allowed retry. The two failures were different scenario-order symptoms (`features/02.タスク.feature:11` first, then `features/04.ノート.feature:5`), matching the known Cucumber preference/state leakage class documented in `CLAUDE.md`. No Phase 16-01 app runtime files were changed.

## Verification

- `bin/rails test test/i18n/locales_parity_test.rb` — PASS (`1 runs, 4 assertions, 0 failures, 0 errors`)
- `bin/rails test test/i18n/rails_i18n_smoke_test.rb` — PASS (`2 runs, 2 assertions, 0 failures, 0 errors`)
- `bin/rails test test/i18n/` — PASS (`3 runs, 6 assertions, 0 failures, 0 errors`)
- `bin/rails runner "YAML.load_file(...); ...; puts 'ok'"` — PASS (`ok`)
- `bin/rails test` — PASS (`138 runs, 700 assertions, 0 failures, 0 errors`)
- `NODENV_VERSION=20.19.4 yarn run lint` — PASS
- `bundle exec rake dad:test` — FAILED twice with different known flaky scenarios; recorded as residual risk, not attributed to this plan's locale catalog/test-only changes.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Ready for `16-02-PLAN.md`: layout/menu/controller substitutions can now reference `nav.*` and `flash.errors.generic` without missing-translation risk.

## Self-Check: PASSED

All Plan 16-01 tasks and acceptance criteria are implemented, committed, and verified. The only non-green command is the known flaky `dad:test` phase-gate suite, which failed on different unrelated scenarios across the required retry.

---
*Phase: 16-core-shell-and-shared-messages-translation*
*Completed: 2026-05-01*
