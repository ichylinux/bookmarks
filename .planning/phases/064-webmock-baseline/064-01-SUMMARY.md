---
phase: 064-webmock-baseline
plan: "01"
subsystem: testing
tags: [webmock, minitest, cucumber, http-stubbing, faraday, capybara, selenium]

requires: []
provides:
  - "webmock gem in :test group (3.26.2)"
  - "test/support/webmock.rb — WebMock global config auto-loaded by Minitest and Cucumber"
  - "WebMock.disable_net_connect!(allow_localhost: true) — external HTTP blocked in all tests"
  - "WebMock stub for fixture feed URLs (slashdot) so Feed#retrieve_feed does not escape"
affects:
  - "065-webmock-migrate"
  - "066-webmock-cucumber"

tech-stack:
  added:
    - "webmock 3.26.2 (crack 1.0.1, hashdiff 1.2.1 as dependencies)"
  patterns:
    - "WebMock global config in test/support/webmock.rb — single file covers both Minitest and Cucumber via Dir[test/support/*.rb] auto-load"
    - "WebMock.stub_request at global scope via WebMock.stub_request (not bare stub_request) to avoid NoMethodError inside class_eval context"
    - "Fixture URL stubs declared in test/support/webmock.rb alongside disable_net_connect! for co-location"

key-files:
  created:
    - "test/support/webmock.rb"
  modified:
    - "Gemfile"
    - "Gemfile.lock"

key-decisions:
  - "Use require 'webmock/minitest' not require 'webmock' — installs Minitest::Test#teardown hook for WebMock.reset! between tests"
  - "Use allow_localhost: true to keep Capybara Puma server and Selenium ChromeDriver on 127.0.0.1 unblocked"
  - "Stub fixture feed URLs (slashdot) at global scope in webmock.rb — WebMock::NetConnectNotAllowedError is an Exception not StandardError so it bypasses Feed#feed rescue => e"
  - "Use WebMock.stub_request (not bare stub_request) because test/support/*.rb is class_eval'd into ActiveSupport::TestCase where stub_request is not a method"

patterns-established:
  - "Pattern 1: Global WebMock stubs for fixture-referenced external URLs belong in test/support/webmock.rb alongside disable_net_connect!"
  - "Pattern 2: Phases 65-66 add per-test stub_request calls; global fixture stubs live here permanently"

requirements-completed:
  - HTTP-01

duration: 25min
completed: 2026-05-14
---

# Phase 064 Plan 01: WebMock Baseline Summary

**webmock 3.26.2 added to :test Gemfile group; test/support/webmock.rb blocks all external HTTP with localhost allowlist and fixture feed stubs covering both Minitest and Cucumber suites**

## Performance

- **Duration:** ~25 min
- **Started:** 2026-05-14T13:00:00Z
- **Completed:** 2026-05-14T13:25:00Z
- **Tasks:** 2
- **Files modified:** 3 (Gemfile, Gemfile.lock, test/support/webmock.rb)

## Accomplishments

- webmock 3.26.2 installed in :test bundle with no version pin
- test/support/webmock.rb created: `require 'webmock/minitest'` + `WebMock.disable_net_connect!(allow_localhost: true)` auto-loaded by both Minitest (via test_helper.rb) and Cucumber (via features/support/test_support.rb)
- All three suites green: 364 Minitest runs (0 failures), 24 Cucumber scenarios (0 failed), ESLint clean
- WebMock.net_connect_allowed? returns false in test environment (BLOCKED confirmed)

## Task Commits

Each task was committed atomically:

1. **Task 1: Add webmock to Gemfile :test group** - `f819448` (chore)
2. **Task 2: Create test/support/webmock.rb** - `8729253` (feat)

**Plan metadata:** (committed with SUMMARY)

## Files Created/Modified

- `test/support/webmock.rb` - WebMock global config: disable_net_connect! + localhost allowlist + fixture feed stubs
- `Gemfile` - Added `gem 'webmock'` to :test group
- `Gemfile.lock` - Updated with webmock 3.26.2, crack 1.0.1, hashdiff 1.2.1

## Decisions Made

- Used `require 'webmock/minitest'` — installs WebMock.enable! and the Minitest::Test#teardown hook that calls WebMock.reset! after each test, preventing stub bleed
- Used `allow_localhost: true` — covers localhost/127.0.0.1/::1; necessary for Capybara Puma server and Selenium ChromeDriver
- Used `WebMock.stub_request` (fully-qualified) not bare `stub_request` — bare form causes NoMethodError when called inside `class_eval` context (test_helper.rb evaluates support files into ActiveSupport::TestCase)

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical] Added WebMock stubs for fixture feed URLs**

- **Found during:** Task 2 (creating test/support/webmock.rb)
- **Issue:** RESEARCH.md stated "existing prepend stubs short-circuit before any real HTTP reaches WebMock" but this only covered XClient and MastodonClient. Feed#retrieve_feed uses Daddy::HttpClient (Faraday) to fetch the RSS feed URL directly. The fixture feed (id: 1) has feed_url 'http://slashdot.jp/slashdotjp.rss'. When Cucumber visits /feeds/1, FeedsController#show calls feed.feed? which triggers retrieve_feed. WebMock::NetConnectNotAllowedError is an Exception subclass (not StandardError), so it bypasses the `rescue => e` guard in Feed#feed and propagates as a 500 — all 24 Cucumber scenarios failed.
- **Fix:** Added `WebMock.stub_request(:get, /slashdot/).to_return(...)` with a minimal RSS 2.0 body in test/support/webmock.rb. This covers both fixture feed URLs (slashdot.jp and rss.slashdot.org).
- **Files modified:** test/support/webmock.rb
- **Verification:** All 24 Cucumber scenarios passed after fix; bin/rails test 364 runs 0 failures
- **Committed in:** 8729253 (Task 2 commit)

---

**Total deviations:** 1 auto-fixed (Rule 2 - missing critical fixture HTTP stub)
**Impact on plan:** Fix was essential for Cucumber green bar. Correctly identified that Feed#retrieve_feed was an unaccounted external HTTP call path. Scope-appropriate: the stub is minimal and permanent fixture infrastructure.

## Issues Encountered

- `stub_request` bare call inside class_eval context fails with NoMethodError — must use `WebMock.stub_request`. This is documented in RESEARCH.md Pitfall 1 context (class_eval affects method lookup) but was not anticipated for this specific call. Fixed immediately.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- WebMock infrastructure complete; Phases 65-66 can proceed to migrate existing XClient/MastodonClient prepend stubs to WebMock stub_request calls
- The slashdot fixture stubs in webmock.rb are permanent baseline; feed-specific per-test stubs (if any are needed in Phase 65-66) should use stub_request in individual test files
- Cucumber's WebMock.reset! between scenarios is NOT yet wired (per plan scope); Phase 66 adds `After { WebMock.reset! }` hook — no Cucumber test in Phase 64 sets stubs so this gap has no current impact

## Known Stubs

- `test/support/webmock.rb` line 27: `WebMock.stub_request(:get, /slashdot/)` returns empty RSS body — intentional fixture stub, not a placeholder. Will remain as permanent baseline infrastructure.

---
*Phase: 064-webmock-baseline*
*Completed: 2026-05-14*
