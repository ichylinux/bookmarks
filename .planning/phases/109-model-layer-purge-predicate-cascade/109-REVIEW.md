---
phase: 109-admin-account-purge-model-controller
reviewed: 2025-05-22T10:00:00Z
depth: standard
files_reviewed: 7
files_reviewed_list:
  - app/models/user.rb
  - app/controllers/admin/users_controller.rb
  - app/views/admin/users/index.html.erb
  - app/views/admin/users/confirm_purge.html.erb
  - config/routes.rb
  - test/models/user_purge_test.rb
  - test/controllers/admin/users_controller_test.rb
findings:
  critical: 0
  warning: 1
  info: 2
  total: 3
status: issues_found
---

# Phase 109: Code Review Report

## Summary

The implementation of the administrative account purge (hard-delete) logic is robust, safe, and efficient. It correctly uses database transactions and `delete_all` to perform bulk deletions while bypassing expensive ActiveRecord callbacks and instantiation overhead. The security model is sound, restricted to administrators, and includes a 90-day safety buffer. Coverage of associated tables is currently 100% based on the current database schema.

## Narrative Findings (AI reviewer)

### WR-01: Hardcoded table list in `User#purge!` creates maintenance risk

**File:** `app/models/user.rb:127-140`
**Issue:** The `purge!` method explicitly lists every associated table to be deleted. While this is efficient, it introduces a significant risk of orphaning records if new models with a `user_id` are added to the application in the future without updating this method. Since the database lacks foreign key constraints, orphaned records would remain in the database indefinitely.
**Fix:**
Consider deriving the list of associations or models dynamically, or at least adding a comment near new associations to remind developers to update `purge!`. Alternatively, use a private constant to manage the list of "purgable" associations.

```ruby
  PURGE_ASSOCIATIONS = %i[
    bookmarks feeds mastodon_accounts notes portal_layouts portals
    preference todos visited_links x_accounts x_api_calls
  ].freeze

  def purge!
    raise NotPurgeableError unless purgeable?

    transaction do
      PURGE_ASSOCIATIONS.each do |assoc|
        send(assoc).delete_all
      end
      delete
    end
  end
```
*(Note: This requires adding `has_many :mastodon_accounts` and other missing inverse associations to `User` first).*

---

### IN-01: Missing `has_many :mastodon_accounts` association

**File:** `app/models/user.rb`
**Issue:** The `User` model lacks a `has_many :mastodon_accounts` association, even though `MastodonAccount` belongs to `User`. While `purge!` handles the deletion explicitly using the class name, the lack of an inverse association is a minor quality defect and prevents using association-based deletion.
**Fix:** Add `has_many :mastodon_accounts, dependent: :destroy` (or similar) to `app/models/user.rb`.

---

### IN-02: Redundant `dependent: :destroy` on `x_accounts` association

**File:** `app/models/user.rb:29`
**Issue:** `has_many :x_accounts, dependent: :destroy` is defined, but `User#purge!` uses `delete` on the user record, which bypasses `dependent: :destroy` callbacks. While `purge!` manually calls `XAccount.delete_all`, the `dependent: :destroy` option on the association is misleading in the context of a hard-delete.
**Fix:** This is mostly a documentation/consistency issue. It's safe to keep for normal `destroy` operations (if any), but be aware it doesn't trigger during `purge!`.

---

_Reviewed: 2025-05-22_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
