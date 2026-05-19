---
phase: 90-oauth2-email-scope-wiring
plan: 01
subsystem: auth
tags: [omniauth, twitter2, oauth2, email, devise]

requires:
  - phase: []
    provides: []
provides:
  - "OAUTH-03: :twitter2 re-auth branch overwrites dummy email with real X email"
  - "OAUTH-01 verified: users.email scope present in devise.rb (comment added)"
  - "OAUTH-02 verified: new-user create branch stores real email (comment added)"
  - "Three test methods covering all OAUTH-03 re-auth email scenarios"
affects: [any phase touching User.from_omniauth or twitter2 auth flow]

tech-stack:
  added: []
  patterns: [conditional attrs hash before assign_attributes for selective field updates]

key-files:
  created: []
  modified:
    - app/models/user.rb
    - test/models/user_test.rb

key-decisions:
  - "Use user.has_valid_email? guard (already defined) rather than inlining dummy regex"
  - "Use data['email'].present? (not != nil) to handle nil and absent-key cases from OmniAuth"
  - "save(validate: false) path unchanged — consistent with all other re-auth attribute updates"
  - "Collision handling: skip silently via save(validate: false), accepted per threat model T-90-03"

patterns-established:
  - "Build attrs hash as local variable before assign_attributes when conditional field merging is needed"
  - "ensure block re-fetches fixture via users(:fixture_label) before update_columns to avoid stale-ref issues"

requirements-completed: [OAUTH-01, OAUTH-02, OAUTH-03]

duration: 8min
completed: 2026-05-19
---

# Phase 90 Plan 01: OAuth2 Email Scope Wiring Summary

**twitter2 re-auth now overwrites dummy_UUID@example.com with real X-provided email using has_valid_email? guard and attrs hash pattern**

## Performance

- **Duration:** 8 min
- **Started:** 2026-05-19T13:36:51Z
- **Completed:** 2026-05-19T13:44:30Z
- **Tasks:** 3
- **Files modified:** 2

## Accomplishments
- OAUTH-03 implemented: `:twitter2` re-auth branch conditionally updates `email` when `data['email'].present? && !user.has_valid_email?`
- OAUTH-01 confirmed: `users.email` scope in `config/initializers/devise.rb` — inline comment added
- OAUTH-02 confirmed: `data['email'].presence || "dummy_..."` in create branch — inline comment added
- Three new Minitest methods covering dummy-email-updated, real-email-preserved, X-email-absent-unchanged scenarios
- Full tri-suite gate passed: 485 Minitest runs (0 failures), ESLint clean, 27 Cucumber scenarios (27 passed)

## Task Commits

1. **Tasks 1+2: OAUTH-03 model change + 3 test methods** - `823f1c0` (feat)
2. **Plan metadata** - (docs commit below)

## Files Created/Modified
- `app/models/user.rb` - Added attrs hash pattern with conditional email key in `:twitter2` if-user block; added OAUTH-01 and OAUTH-02 inline comments
- `test/models/user_test.rb` - Added 3 test methods: `test_twitter2_from_omniauth_updates_dummy_email_on_reauth`, `test_twitter2_from_omniauth_does_not_overwrite_real_email_on_reauth`, `test_twitter2_from_omniauth_does_not_change_email_when_x_provides_none`

## Decisions Made
- Used `user.has_valid_email?` (already defined at lines 101-105) rather than inlining a regex — avoids duplication and uses the canonical method
- Used `data['email'].present?` per research pitfall 3 — handles nil and absent-key cases from OmniAuth info hash
- `save(validate: false)` path left unchanged — consistent with all other fields in this branch

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- OAUTH-01, OAUTH-02, OAUTH-03 all satisfied
- X users who re-authenticate will have their dummy email replaced with their real X email
- No migrations, routes, or view changes needed for this feature

---
*Phase: 90-oauth2-email-scope-wiring*
*Completed: 2026-05-19*
