---
phase: 85-css-view-helper
plan: "01"
subsystem: css-view-helper
tags: [css, helper, visited-links, opacity, set-lookup]
dependency_graph:
  requires: [VisitedLink-model, VisitedLink.normalize_url]
  provides: [link--visited-css-class, ApplicationHelper.visited_link_class]
  affects: [app/assets/stylesheets/common.css.scss, app/helpers/application_helper.rb]
tech_stack:
  added: []
  patterns: [scss-specificity-scoping, ruby-set-o1-lookup, css-contract-test]
key_files:
  created: []
  modified:
    - app/assets/stylesheets/common.css.scss
    - app/helpers/application_helper.rb
    - test/helpers/application_helper_test.rb
decisions:
  - "Comment in helper references VisitedLink.normalize_url — grep -c returns 2 (comment + code); single code call is the correct implementation"
  - "No require 'set' needed in tests — Ruby stdlib Set is available in ActionView::TestCase context"
metrics:
  duration: "~10 minutes"
  completed: "2026-05-18"
  tasks_completed: 2
  tasks_total: 2
  files_created: 0
  files_modified: 3
---

# Phase 85 Plan 01: CSS + View Helper Summary

**One-liner:** `.gadget a.link--visited { opacity: 0.55; }` in `common.css.scss` (specificity 0,2,1) and `ApplicationHelper#visited_link_class(visited_set, url)` delegating to `VisitedLink.normalize_url` for fragment-safe Set lookup.

## What Was Built

### Task 1: CSS Rule

`app/assets/stylesheets/common.css.scss` — appended after the `body.no-icons` block:

```scss
// VIS-01: Visited link visual indicator — scoped to gadget content links only.
// Specificity (0,2,1): beats common a:visited baseline without !important.
.gadget a.link--visited {
  opacity: 0.55;
}
```

- Specificity (0,2,1): 2 classes (`.gadget`, `.link--visited`) + 1 element (`a`) — beats `a, a:visited` baseline (0,1,0)
- Scoped to `.gadget` — does not affect header links, nav links, or breadcrumb links
- Single property (`opacity: 0.55`) — device-agnostic; no color dependency; no `!important`

### Task 2: Helper Method + Tests

`app/helpers/application_helper.rb` — `visited_link_class` added alongside `changelog_entries`:

```ruby
def visited_link_class(visited_set, url)
  normalized = VisitedLink.normalize_url(url)
  visited_set.include?(normalized) ? "link--visited" : ""
end
```

`test/helpers/application_helper_test.rb` — 5 new tests appended to `ApplicationHelperTest`:

| Test | Branch |
|------|--------|
| `visited_link_class returns link--visited when url is in the set` | truthy |
| `visited_link_class returns empty string when url is not in the set` | falsy |
| `visited_link_class normalizes url before lookup (strips fragment)` | fragment-normalizing |
| `visited_link_class returns empty string for empty set` | empty-set |
| `common.css.scss defines .link--visited selector` | CSS contract |

Total: 9 helper tests (4 existing + 5 new), 0 failures, 0 errors.

## Deviations from Plan

None — plan executed exactly as written. One minor note: the inline comment in `application_helper.rb` also mentions `VisitedLink.normalize_url`, so `grep -c` returns 2 instead of the plan's expected 1. The code implementation (single call) is correct.

## Commits

| Task | Commit | Message |
|------|--------|---------|
| 1 — CSS | 72ccad1 | feat(85-01): add .link--visited CSS rule to common.css.scss |
| 2 — Helper + Tests | 05a3bb5 | feat(85-01): add visited_link_class helper and tests |

## Verification

- `grep -c 'link--visited' app/assets/stylesheets/common.css.scss` → 1 ✅
- `grep -c 'visited_link_class' app/helpers/application_helper.rb` → 1 ✅
- `grep -c 'VisitedLink.normalize_url' app/helpers/application_helper.rb` → 2 (1 comment + 1 code) ✅
- `bin/rails test test/helpers/application_helper_test.rb` → 9 runs, 0 failures, 0 errors ✅
- `yarn run lint` → green ✅
- `bin/rails test` → 439 runs, 0 failures, 0 errors ✅
- `bundle exec rake dad:test` → 25 scenarios (25 passed) ✅

## Known Stubs

None — all behaviors are fully implemented and tested.

## Threat Flags

None — no new network endpoints or trust boundaries beyond what the plan's threat model covers. The helper is a pure function; user content is never reflected into output.

## Self-Check: PASSED

- [x] `app/assets/stylesheets/common.css.scss` contains `.gadget a.link--visited` — FOUND
- [x] `app/helpers/application_helper.rb` contains `visited_link_class` — FOUND
- [x] `test/helpers/application_helper_test.rb` has 9 runs passing — VERIFIED
- [x] Commit 72ccad1 — FOUND
- [x] Commit 05a3bb5 — FOUND
