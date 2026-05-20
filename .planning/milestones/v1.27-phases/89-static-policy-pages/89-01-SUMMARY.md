---
phase: 89-static-policy-pages
plan: 01
subsystem: ui
tags: [rails, routes, controller, scss, minitest, i18n]

# Dependency graph
requires: []
provides:
  - PagesController with public /privacy and /terms actions (skip_before_action :authenticate_user!)
  - GET /privacy and GET /terms routes with named helpers privacy_path, terms_path
  - app/views/pages/privacy.html.erb and terms.html.erb stub views (main.landing-page wrapper)
  - app/assets/stylesheets/pages.css.scss with .policy-content, .policy-section-heading, .policy-back-link
  - test/controllers/privacy_controller_test.rb and terms_controller_test.rb (12 tests, 6 passing)
affects: [89-02]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "PagesController: skip_before_action :authenticate_user! without only: qualifier for fully-public controller"
    - "Stub views: minimal main.landing-page wrapper allows 200 status before content is added"
    - "pages.css.scss: .policy-* SCSS classes following landing.css.scss structure pattern"

key-files:
  created:
    - app/controllers/pages_controller.rb
    - app/views/pages/privacy.html.erb
    - app/views/pages/terms.html.erb
    - app/assets/stylesheets/pages.css.scss
    - test/controllers/privacy_controller_test.rb
    - test/controllers/terms_controller_test.rb
  modified:
    - config/routes.rb

key-decisions:
  - "Stub views added in Plan 01 (not Plan 02): without template files Rails returns 406, blocking status tests that must pass in this wave"
  - "Routes placed inside unless ARGV block per PATTERNS.md — matches existing user/auth route placement"
  - "skip_before_action without only: qualifier — both privacy and terms are fully public"

patterns-established:
  - "PagesController pattern: inherit ApplicationController, skip auth entirely, empty actions, views do all rendering"
  - "Stub view pattern: minimal <main class='landing-page'> wrapper lets status/redirect tests go green before YAML+content views exist"

requirements-completed: [PRIV-01, PRIV-02, PRIV-03, TOS-01, TOS-02, TOS-03]

# Metrics
duration: 2min
completed: 2026-05-19
---

# Phase 89 Plan 01: Static Policy Pages — Routes, Controller, CSS, and Tests

**PagesController with public /privacy and /terms routes, .policy-* SCSS classes, and 12-test suite (6 green, 6 red pending Plan 02 content)**

## Performance

- **Duration:** ~2 min
- **Started:** 2026-05-19T12:59:24Z
- **Completed:** 2026-05-19T13:01:36Z
- **Tasks:** 2
- **Files modified:** 7 (1 modified, 6 created)

## Accomplishments
- GET /privacy and GET /terms return HTTP 200 without authentication (skip_before_action works correctly)
- Named route helpers privacy_path and terms_path registered and verified via bin/rails routes
- pages.css.scss created with all three .policy-* selectors and mobile media query (exact UI-SPEC values)
- 12 tests written: 6 pass (status, structure, no-redirect); 6 in expected RED state awaiting Plan 02 views+YAML

## Task Commits

1. **Task 1: Routes, PagesController, stub views, test files** - `7f6fc77` (feat)
2. **Task 2: pages.css.scss** - `2b5173d` (feat)

**Plan metadata:** (see final commit below)

## Files Created/Modified
- `config/routes.rb` - Added GET /privacy and GET /terms inside unless ARGV block
- `app/controllers/pages_controller.rb` - PagesController with skip_before_action :authenticate_user!
- `app/views/pages/privacy.html.erb` - Stub view: `<main class="landing-page">` wrapper
- `app/views/pages/terms.html.erb` - Stub view: `<main class="landing-page">` wrapper
- `app/assets/stylesheets/pages.css.scss` - .policy-content, .policy-section-heading, .policy-back-link + mobile MQ
- `test/controllers/privacy_controller_test.rb` - 6 tests for /privacy (3 pass, 3 red)
- `test/controllers/terms_controller_test.rb` - 6 tests for /terms (3 pass, 3 red)

## Decisions Made
- **Stub views added in Plan 01 (deviation from plan structure):** The plan expected status tests to pass without any view files. Without a template, Rails returns 406 Not Acceptable (not 302 redirect). Adding minimal stub views (`<main class="landing-page"></main>`) resolves this and keeps status/redirect tests green. The stubs are intentional scaffolding for Plan 02 to fill in.
- **Routes inside unless ARGV block:** Follows the established pattern per PATTERNS.md. The unless block guards against loading User model during `dad:setup` Docker builds; simple GET routes for static pages are safe here.
- **skip_before_action without only: qualifier:** Both privacy and terms are fully public — no subset needed.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Added stub view files to fix 406 Not Acceptable blocking status tests**
- **Found during:** Task 1 (after creating routes + controller, running tests)
- **Issue:** Plan expected `test_未認証でprivacyは200を返す` and `test_未認証でtermsは200を返す` to pass without views. Rails returns 406 Not Acceptable when no template exists, causing all 12 tests to fail with assertion errors instead of the planned 6-pass / 6-fail split.
- **Fix:** Created `app/views/pages/privacy.html.erb` and `app/views/pages/terms.html.erb` with minimal `<main class="landing-page"></main>` stubs. Status/structure/no-redirect tests now pass; content tests (h1, h2) remain in RED state as expected.
- **Files modified:** app/views/pages/privacy.html.erb, app/views/pages/terms.html.erb
- **Verification:** 12 runs, 22 assertions, 6 failures (content only), 0 errors, 0 skips
- **Committed in:** 7f6fc77 (Task 1 commit)

---

**Total deviations:** 1 auto-fixed (Rule 1 - bug in plan's test expectation)
**Impact on plan:** Fix essential for meeting the plan's own success criteria. Stub views are intentional scaffolding; Plan 02 replaces them with full content.

## Issues Encountered
None beyond the Rule 1 deviation above.

## User Setup Required
None - no external service configuration required.

## Known Stubs

| File | Description | Resolved by |
|------|-------------|-------------|
| `app/views/pages/privacy.html.erb` | Stub: only `<main class="landing-page"></main>`, no h1/content | Plan 02 (views + YAML) |
| `app/views/pages/terms.html.erb` | Stub: only `<main class="landing-page"></main>`, no h1/content | Plan 02 (views + YAML) |

These stubs are intentional — they enable status tests to pass in Wave 1 while content (YAML, section headings, titles) is delivered in Wave 2 (Plan 02).

## Next Phase Readiness
- Plan 02 (Wave 2) can proceed: PagesController, routes, CSS, and test files are all in place
- Plan 02 must: add YAML locale keys under `pages.privacy.*` and `pages.terms.*`, replace stub views with full ERB templates
- After Plan 02, all 12 tests should be green

## Self-Check: PASSED

---
*Phase: 89-static-policy-pages*
*Completed: 2026-05-19*
