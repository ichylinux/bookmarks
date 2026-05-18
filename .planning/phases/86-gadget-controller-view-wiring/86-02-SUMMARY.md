---
phase: 86-gadget-controller-view-wiring
plan: 02
subsystem: gadget-controller-tests
tags: [visited-links, integration-tests, n-plus-one, query-counter]
dependency_graph:
  requires: [86-01]
  provides: [visited-class-controller-integration-tests, n-plus-one-guard-tests]
  affects: [feeds_controller_test, mastodon_accounts_controller_test, x_accounts_controller_test]
tech_stack:
  added: [ActiveSupport::Notifications.subscribed for query counting]
  patterns: [LIFO-webmock-stub, delete_all-isolation, count_visited_link_queries-helper]
key_files:
  created:
    - test/support/query_counter.rb
  modified:
    - test/controllers/feeds_controller_test.rb
    - test/controllers/mastodon_accounts_controller_test.rb
    - test/controllers/x_accounts_controller_test.rb
decisions:
  - "query_counter uses ActiveSupport::Notifications.subscribed (auto-unsubscribes after block)"
  - "Lambda signature ->(*, payload) captures all positional args, payload is last"
  - "stub_feed_with_items uses exact URL match (not regex) for LIFO priority over global /slashdot/ stub"
  - "X accounts tests use ensure acc&.destroy for cleanup, matching existing pattern"
metrics:
  duration: "~5 minutes"
  completed: "2025-01-27"
  tasks_completed: 2
  tasks_total: 2
  files_changed: 4
---

# Phase 86 Plan 02: Query Counter + Visited-Class Controller Integration Tests Summary

**One-liner:** `count_visited_link_queries` support helper + 9 new controller integration tests (3 per gadget) verifying visited-class rendering and N+1 absence across feeds, mastodon, and X gadgets.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Query counter support + feeds controller tests | 8e2e24f | test/support/query_counter.rb, test/controllers/feeds_controller_test.rb |
| 2 | Mastodon + X controller visited link integration tests | 8e2e24f | test/controllers/mastodon_accounts_controller_test.rb, test/controllers/x_accounts_controller_test.rb |

## What Was Built

### query_counter.rb
```ruby
def count_visited_link_queries
  count = 0
  callback = ->(*, payload) { count += 1 if payload[:sql].to_s.include?('visited_links') }
  ActiveSupport::Notifications.subscribed(callback, 'sql.active_record') { yield }
  count
end
```
Auto-loaded into all test cases via `test_helper.rb` `support/*.rb` glob.

### New Test Methods (9 total)

**FeedsControllerTest (3 new):**
- `test_show_renders_visited_class_on_visited_feed_item` — visited URL → `a.link--visited` present
- `test_show_does_not_render_visited_class_on_unvisited_feed_item` — unvisited URL → no `a.link--visited`
- `test_show_issues_single_visited_links_query_regardless_of_item_count` — 3 items → exactly 1 query

**MastodonAccountsControllerTest (3 new):**
- `test_show_renders_visited_class_on_visited_toot`
- `test_show_does_not_render_visited_class_on_unvisited_toot`
- `test_show_issues_single_visited_links_query_for_multiple_toots`

**XAccountsControllerTest (3 new):**
- `test_show_renders_visited_class_on_visited_tweet` (signs in as `twitter_user`)
- `test_show_does_not_render_visited_class_on_unvisited_tweet`
- `test_show_issues_single_visited_links_query_for_multiple_tweets`

### Private helper: stub_feed_with_items
Added to FeedsControllerTest private section — builds inline RSS 2.0 XML and registers exact-URL WebMock stub (LIFO priority over global `/slashdot/` regex stub).

## Verification Results

```
bin/rails test test/controllers/feeds_controller_test.rb → 19 runs, 0 failures ✓
bin/rails test test/controllers/mastodon_accounts_controller_test.rb → 18 runs, 0 failures ✓
bin/rails test test/controllers/x_accounts_controller_test.rb → 16 runs, 0 failures ✓
bin/rails test (full suite) → 448 runs, 2015 assertions, 0 failures, 0 errors, 0 skips ✓
bundle exec rake dad:test → 25 scenarios (25 passed) ✓
grep -c 'link--visited' test/controllers/feeds_controller_test.rb → 2 ✓
grep -c 'link--visited' test/controllers/mastodon_accounts_controller_test.rb → 2 ✓
grep -c 'link--visited' test/controllers/x_accounts_controller_test.rb → 2 ✓
```

## Deviations from Plan

None — plan executed exactly as written.

## Known Stubs

None.

## Threat Flags

None — test files only, no new production surface.
