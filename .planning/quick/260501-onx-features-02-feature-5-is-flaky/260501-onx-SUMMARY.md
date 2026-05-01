---
status: complete
quick_id: 260501-onx
slug: features-02-feature-5-is-flaky
date: 2026-05-01
commit: 60c134b
---

# Quick Task 260501-onx: features/02.タスク.feature:5 is flaky

## What changed

- Added a `Before` hook in `features/support/env.rb` to reset browser session and fixture user preference defaults (`theme`, `use_todo`, `use_note`, `default_priority`, `locale`) before each scenario.
- Updated `features/support/login.rb` `sign_in` helper to use locale-independent form field names (`user[email]`, `user[password]`, `user[otp_attempt]`) and handle already-authenticated redirects safely.
- Updated `features/step_definitions/todos.rb` to remove locale-label-dependent preference interactions and use stable todo action selectors.

## Result

- `features/02.タスク.feature` passed repeatedly under fixed random seed (`7020`) without reproducing the flaky failure.
- Full gate suites passed:
  - `yarn run lint`
  - `bin/rails test`
  - `bundle exec rake dad:test`
