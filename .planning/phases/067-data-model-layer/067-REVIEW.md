---
phase: 067-data-model-layer
reviewed: 2026-05-15T00:00:00Z
depth: standard
files_reviewed: 6
files_reviewed_list:
  - db/migrate/20260515000000_add_portal_column_count_to_preferences.rb
  - test/models/portal_test.rb
  - app/models/preference.rb
  - app/models/portal.rb
  - db/schema.rb
  - test/models/preference_test.rb
findings:
  critical: 0
  warning: 0
  info: 2
  total: 2
status: clean
---

# Phase 067: Code Review Report

**Reviewed:** 2026-05-15T00:00:00Z
**Depth:** standard
**Files Reviewed:** 6
**Status:** clean

## Summary

This phase adds a `portal_column_count` column to `preferences` and wires it through `Portal#portal_column_count` and `Portal#portal_columns`. The migration, schema, model validation, and delegation are structurally sound. The newly added tests cover the happy path and the out-of-range `column_no` boundary case adequately.

All Critical and Warning findings from the initial review have been resolved. Two Info items remain open.

---

## Fixes Applied

### CR-01 — Resolved

**`update_layout` empty `valid_layouts` crash fixed.**

`app/models/portal.rb:48` now reads:

```ruby
PortalLayout.where(user_id: user.id).where.not(id: valid_layouts).each(&:destroy)
```

ActiveRecord's `where.not(id: [])` safely expands to a no-op (deletes all matching rows when the array is empty, which is the correct semantic) without the `ArgumentError` or `NOT IN (NULL)` misfire from the raw SQL form. Fix is correct.

### WR-01 — Resolved

**`portal_columns` memoization is now count-aware.**

`app/models/portal.rb:11-13` now reads:

```ruby
current_count = portal_column_count
return @portal_columns if @portal_columns && @portal_columns_count == current_count

@portal_columns_count = current_count
```

The memoized result is invalidated whenever `portal_column_count` returns a different value from when it was last computed. Fix is correct.

### WR-02 — Resolved

**`update_layout` nil-params guard added.**

`app/models/portal.rb:31-32` now reads:

```ruby
def update_layout(params = {})
  params ||= {}
```

When the caller passes `nil` explicitly (e.g., `params[:portal]` is absent from the request), the `||=` guard normalises it to `{}` before `params.each` is called. Fix is correct.

---

## Info

### IN-01: `Portal#update_layout` has zero test coverage

**File:** `test/models/portal_test.rb`

**Issue:** `update_layout` is the only public mutation method on `Portal` and it is entirely untested. The three new portal tests cover `portal_column_count` delegation and `portal_columns` distribution, but no test exercises the layout-save path. This would have caught CR-01 before it reached review.

**Fix:** Add tests for `update_layout` covering: normal layout save, all-empty columns, params with `nil`, and the idempotent re-save case.

### IN-02: `Preference.default_preference` does not explicitly set `portal_column_count`

**File:** `app/models/preference.rb:28-35`

**Issue:** `default_preference` builds a new unsaved `Preference` object but does not explicitly assign `portal_column_count`. The method sets `default_priority`, `theme`, `use_todo`, and `use_calendar` explicitly. The `portal_column_count` value is implicitly `3` because Rails 8 applies DB column defaults to new AR instances — but this is invisible to a reader of `default_preference` and not documented. If a developer adds a test that serializes or inspects the returned object before the schema cache is warm (e.g., in an isolated unit test context), `portal_column_count` would be `nil` and fail the inclusion validator.

**Fix:** Add an explicit assignment for clarity and resilience:

```ruby
def self.default_preference(user)
  ret = self.new(user: user)
  ret.default_priority = Todo::PRIORITY_NORMAL
  ret.theme = "modern"
  ret.use_todo = true
  ret.use_calendar = true
  ret.portal_column_count = PORTAL_COLUMN_COUNTS.first
  ret
end
```

---

_Reviewed: 2026-05-15T00:00:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
