---
phase: 109-model-layer-purge-predicate-cascade
reviewed: 2026-05-22T00:00:00Z
depth: standard
files_reviewed: 13
files_reviewed_list:
  - app/controllers/admin/users_controller.rb
  - app/models/user.rb
  - app/views/admin/users/confirm_purge.html.erb
  - app/views/admin/users/index.html.erb
  - config/locales/en.yml
  - config/locales/ja.yml
  - config/routes.rb
  - features/12.管理者アカウント完全削除.feature
  - features/step_definitions/admin_purge.rb
  - features/support/hooks.rb
  - test/controllers/admin/users_controller_test.rb
  - test/i18n/admin_users_i18n_test.rb
  - test/models/user_purge_test.rb
findings:
  critical: 0
  warning: 1
  info: 0
  total: 1
status: issues_found
---

# Phase 109: Code Review Report

**Reviewed:** 2026-05-22T00:00:00Z  
**Depth:** standard  
**Files Reviewed:** 13  
**Status:** issues_found

## Summary

Reviewed the full requested scope for purge flow updates (controller/model/view/routes/locales + feature/test coverage).  
No direct security vulnerabilities or purge authorization bypass were found in reviewed source, but one functional correctness issue remains in admin list rendering.

## Narrative Findings (AI reviewer)

## Warnings

### WR-01: Admin list can show the wrong X account name

**File:** `app/views/admin/users/index.html.erb:22`  
**Issue:** The view renders X username via:

```ruby
user.x_accounts.reject(&:deleted?).sort_by(&:id).first&.username
```

This ignores account selection state (`selected`) and can display an arbitrary non-deleted account when multiple X accounts exist. That can misidentify users in admin operations.

**Fix:**
Prefer selected account first, then fallback deterministically:

```erb
<% active_accounts = user.x_accounts.reject(&:deleted?) %>
<% primary_account = active_accounts.find(&:selected?) || active_accounts.min_by(&:id) %>
<td><%= primary_account&.username %></td>
```

---

_Reviewed: 2026-05-22T00:00:00Z_  
_Reviewer: the agent (gsd-code-reviewer)_  
_Depth: standard_
