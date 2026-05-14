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
  critical: 1
  warning: 2
  info: 2
  total: 5
status: issues_found
---

# Phase 067: Code Review Report

**Reviewed:** 2026-05-15T00:00:00Z
**Depth:** standard
**Files Reviewed:** 6
**Status:** issues_found

## Summary

This phase adds a `portal_column_count` column to `preferences` and wires it through `Portal#portal_column_count` and `Portal#portal_columns`. The migration, schema, model validation, and delegation are structurally sound. The newly added tests cover the happy path and the out-of-range `column_no` boundary case adequately.

However, one pre-existing method in `portal.rb` — `update_layout` — is brought into scope and contains a crash-level defect when the layout is saved with all-empty columns (empty `valid_layouts` array). This is a BLOCKER because the column-count feature makes it easier to reach this code path (user shrinks from 4 to 3 columns, all gadgets move to valid columns leaving some columns empty). Two additional warnings cover memoization staleness and a nil-params crash path. Two info items cover missing test coverage and an implicit reliance on AR schema defaults.

---

## Critical Issues

### CR-01: `update_layout` crashes / silently misbehaves with empty `valid_layouts`

**File:** `app/models/portal.rb:45`

**Issue:** When `update_layout` is called and all `gadget_ids` arrays in `params` are empty (e.g., all columns have zero gadgets after a drag operation), `valid_layouts` remains `[]`. The query on line 45 then executes:

```ruby
PortalLayout.where('user_id = ? and id not in(?)', user.id, [])
```

In Rails 8 / ActiveRecord 8.1, passing an empty array to a raw SQL `?` placeholder raises `ArgumentError` at runtime, crashing the `save_state` action inside a transaction. Even on adapter versions that silently expand `[]` to `NULL`, `id NOT IN (NULL)` evaluates to `FALSE` for every row — causing zero records to be deleted when all records should be deleted. Either outcome is wrong.

This path is reachable today whenever all gadgets happen to be invisible (`BookmarkGadget#visible?` false, `use_todo` false, `use_calendar` false, no feeds, no accounts). Adding the 4-column option increases the likelihood of encountering all-empty column submissions.

**Fix:** Guard the deletion query against an empty array:

```ruby
# Replace line 45 with:
if valid_layouts.empty?
  PortalLayout.where(user_id: user.id).each(&:destroy)
else
  PortalLayout.where('user_id = ? and id not in(?)', user.id, valid_layouts).each(&:destroy)
end
```

Or use the safer AR form that handles empty arrays correctly in both branches:

```ruby
PortalLayout.where(user_id: user.id).where.not(id: valid_layouts).each(&:destroy)
```

---

## Warnings

### WR-01: `Portal#portal_columns` memoization is stale after `portal_column_count` changes on the same instance

**File:** `app/models/portal.rb:10-11`

**Issue:** `portal_columns` memoizes into `@portal_columns` using `return @portal_columns if @portal_columns`. The `portal_column_count` is read once inside the method and baked into the result array size. If `user.preference.portal_column_count` is updated (e.g., via `update_columns`) while the same `Portal` instance is live, subsequent calls to `portal_columns` return the cached array built with the old count. The new test `test_portal_column_countはpreference設定を委譲する` re-fetches the portal with `Portal.find(portal.id)` specifically to work around this — confirming the staleness is real and observable.

In the view, `@portal` is a single controller-assigned instance. Within a single request this is benign, but the pattern is fragile and could silently produce wrong column counts if the instance is reused across actions (e.g., via controller memoization in a future refactor).

**Fix:** Either clear `@portal_columns` when `portal_column_count` changes, or make memoization dependent on the count value:

```ruby
def portal_columns
  current_count = portal_column_count
  return @portal_columns if @portal_columns && @portal_columns_count == current_count

  @portal_columns_count = current_count
  # ... rest of method unchanged ...
end
```

### WR-02: `update_layout` receives `nil` params without a guard

**File:** `app/models/portal.rb:29`

**Issue:** The method signature is `def update_layout(params = {})`. The default only applies when the argument is absent entirely — not when `nil` is passed explicitly. In `welcome_controller.rb:13`, the call is `update_layout(params[:portal])`. If the request arrives without a `portal` key (e.g., a direct POST to `save_state` without the portal param), `params[:portal]` evaluates to `nil`, and `nil.each` raises `NoMethodError` inside the transaction.

**Fix:** Normalize the argument at the start of the method:

```ruby
def update_layout(params = {})
  params = params.to_h if params.respond_to?(:to_h)
  params ||= {}
  # ...
end
```

Or guard in the controller before calling `update_layout`.

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
