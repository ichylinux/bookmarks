---
phase: 120-instance-selection-ui
status: passed
verified: 2026-06-12
requirements: [INST-01, INST-02]
---

# Phase 120 Verification

**Status:** passed  
**Verified:** 2026-06-12

## Must-Haves

| ID | Requirement | Status | Evidence |
|----|-------------|--------|----------|
| INST-01 | Instance domain input on sign-in and sign-up (ja/en) | PASS | `_oauth_buttons.html.erb`; sessions_controller_test rendering assertions |
| INST-02 | Invalid domain rejected with localized flash before OAuth | PASS | `MastodonInstanceNormalizer`; controller flash + redirect_back; controller tests |
| — | Valid POST stores normalized hostname in session and redirects to Mastodon OAuth | PASS | `mastodon_instances_controller_test` |
| — | Minitest covers normalization and rejection paths | PASS | `mastodon_instance_normalizer_test.rb`, controller + sessions tests |

## Automated Checks

| Suite | Command | Result |
|-------|---------|--------|
| Lint | `yarn run lint` | PASS (0 problems) |
| Minitest | `bin/rails test` | PASS (640 runs, 0 failures) |
| Cucumber | `bundle exec rake dad:test` | PASS (38 scenarios, 0 failed) |

## Key Files Verified

- `app/services/mastodon_instance_normalizer.rb` — strip/normalize/validate hostname
- `app/controllers/users/mastodon_instances_controller.rb` — POST handler, session write, OAuth redirect
- `app/views/devise/shared/_oauth_buttons.html.erb` — instance form on auth pages
- `config/routes.rb` — `POST users/mastodon_instance`
- `config/locales/en.yml`, `config/locales/ja.yml` — `devise.shared.omniauth.mastodon.*`

## Human Verification

None required (covered by Minitest rendering and controller integration tests).

## Gaps

None.
