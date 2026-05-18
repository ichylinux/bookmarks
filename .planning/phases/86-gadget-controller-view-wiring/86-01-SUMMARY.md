---
phase: 86-gadget-controller-view-wiring
plan: 01
subsystem: gadget-controllers-views
tags: [visited-links, controllers, views, helpers, nil-guard]
dependency_graph:
  requires: [84-visited-link-model, 85-visited-link-recording]
  provides: [visited-url-assignment-in-show-actions, visited-class-on-item-links]
  affects: [feeds_controller, mastodon_accounts_controller, x_accounts_controller, application_helper]
tech_stack:
  added: []
  patterns: [before_action-assignment, safe-navigation-operator]
key_files:
  created: []
  modified:
    - app/helpers/application_helper.rb
    - app/controllers/feeds_controller.rb
    - app/controllers/mastodon_accounts_controller.rb
    - app/controllers/x_accounts_controller.rb
    - app/views/feeds/show.html.erb
    - app/views/mastodon_accounts/show.html.erb
    - app/views/x_accounts/show.html.erb
decisions:
  - "Nil-guard via &. safe navigation; no default Set — visited_set is nil only when helper called without before_action"
  - "assign_visited_urls not DRY'd into ApplicationController — each controller independently responsible per Phase 86 scope"
  - "Item loop links use **link_opts splat + class: keyword — safe because link_opts never has :class key"
metrics:
  duration: "~5 minutes"
  completed: "2025-01-27"
  tasks_completed: 2
  tasks_total: 2
  files_changed: 7
requirements-completed:
  - GAD-01
  - GAD-02
  - GAD-03
  - GAD-04
---

# Phase 86 Plan 01: Helper nil-guard + Controller/View Wiring Summary

**One-liner:** Nil-guarded `visited_link_class` helper + `before_action :assign_visited_urls` in 3 gadget controllers + `class: visited_link_class(...)` on item-loop links in 3 show views.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Helper nil-guard + before_action in 3 controllers | b33d58d | application_helper.rb, feeds_controller.rb, mastodon_accounts_controller.rb, x_accounts_controller.rb |
| 2 | Add visited_link_class to item loop links in 3 show views | 2958841 | feeds/show.html.erb, mastodon_accounts/show.html.erb, x_accounts/show.html.erb |

## What Was Built

### Helper Nil-guard (GAD-04)
`visited_link_class` in `ApplicationHelper` changed from `visited_set.include?` to `visited_set&.include?`. Returns `""` safely when `visited_set` is nil — no `NoMethodError` raised.

### Controller before_action (GAD-04)
All three gadget controllers now have:
```ruby
before_action :assign_visited_urls, only: [:show]
```
with a private method:
```ruby
def assign_visited_urls
  @visited_urls = VisitedLink.urls_for(current_user)
end
```
This fires a single batched `SELECT` into `visited_links` before rendering — no N+1 possible.

### View Item Link Class (GAD-01, GAD-02, GAD-03)
Each `<li>` item loop link updated to:
- `link_to e.title, e.url, **link_opts, class: visited_link_class(@visited_urls, e.url)` (feeds)
- `link_to item[:text], item[:url], **link_opts, class: visited_link_class(@visited_urls, item[:url])` (mastodon, x)

Header/title links (`@feed.title`, `@mastodon_account.title`, `@x_account.title`) unchanged.

## Verification Results

```
grep -c assign_visited_urls app/controllers/feeds_controller.rb → 2 ✓
grep -c assign_visited_urls app/controllers/mastodon_accounts_controller.rb → 2 ✓
grep -c assign_visited_urls app/controllers/x_accounts_controller.rb → 2 ✓
grep 'visited_set&\.include?' app/helpers/application_helper.rb → 1 match ✓
grep -c visited_link_class app/views/feeds/show.html.erb → 1 ✓
grep -c visited_link_class app/views/mastodon_accounts/show.html.erb → 1 ✓
grep -c visited_link_class app/views/x_accounts/show.html.erb → 1 ✓
bin/rails test → 439 runs, 1980 assertions, 0 failures, 0 errors, 0 skips ✓
```

## Deviations from Plan

None — plan executed exactly as written.

## Known Stubs

None.

## Threat Flags

None — no new network endpoints, auth paths, file access patterns, or schema changes introduced.
