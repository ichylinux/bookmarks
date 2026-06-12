---
phase: 120-instance-selection-ui
reviewed: 2026-06-12T18:35:00Z
depth: standard
files_reviewed: 9
files_reviewed_list:
  - app/services/mastodon_instance_normalizer.rb
  - app/controllers/users/mastodon_instances_controller.rb
  - app/views/devise/shared/_oauth_buttons.html.erb
  - app/assets/stylesheets/devise.css.scss
  - config/routes.rb
  - config/locales/en.yml
  - config/locales/ja.yml
  - test/services/mastodon_instance_normalizer_test.rb
  - test/controllers/users/mastodon_instances_controller_test.rb
findings:
  critical: 0
  warning: 0
  info: 1
  total: 1
findings_fixed:
  critical: 0
  warning: 0
  info: 0
status: clean
fix_notes: "No fixes required. IN-01 notes private-IP blocklist deferred per CONTEXT."
---

# Phase 120: Code Review Report

**Reviewed:** 2026-06-12T18:35:00Z  
**Depth:** standard  
**Files Reviewed:** 9  
**Status:** clean

## Summary

Phase 120 adds Mastodon instance domain capture on auth pages with normalization, validation, session storage, and localized error handling before OmniAuth redirect. Implementation matches CONTEXT/UI-SPEC and integrates with Phase 119 strategy (`session[:mastodon_instance]`). Controller clears stale OAuth credentials on instance change.

## Info

### IN-01: Private-IP / SSRF Blocklist Deferred (Expected)

**File:** `app/services/mastodon_instance_normalizer.rb`

**Issue:** Rejects obvious IP literals but does not block private/reserved ranges (e.g. `10.0.0.1` would be rejected as IP; `internal.corp` would pass). CONTEXT defers hostname blocklist unless trivial.

**Action:** No change in this phase.

---

_Reviewed: 2026-06-12T18:35:00Z_  
_Reviewer: Claude (gsd-code-reviewer)_
