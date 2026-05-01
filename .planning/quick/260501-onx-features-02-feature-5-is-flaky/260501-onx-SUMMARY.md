---
status: complete
quick_id: 260501-onx
slug: features-02-feature-5-is-flaky
date: 2026-05-01
commit: 93d16db
---

# Quick Task 260501-onx: features/02.タスク.feature:5 is flaky

## What changed

- Added a `Before` hook in `features/support/env.rb` to reset browser session and fixture user preference defaults (`theme`, `use_todo`, `use_note`, `default_priority`, `locale`) before each scenario.
- Updated `features/support/login.rb` `sign_in` helper to use locale-independent form field names (`user[email]`, `user[password]`, `user[otp_attempt]`).
- Updated `features/step_definitions/todos.rb` to keep preference changes UI-based (`/preferences`) while using stable element selectors (`#user_preference_attributes_use_todo`, `#user_preference_attributes_default_priority`) and one retry for intermittent DOM lookup timing.

## Result

- `features/02.タスク.feature` passed repeatedly under fixed random seed (`7020`) without reproducing the flaky failure (10 consecutive runs).
- Full gate suites passed:
  - `yarn run lint`
  - `bin/rails test`
  - `bundle exec rake dad:test`
