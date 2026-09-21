---
phase: 131-feed-visit-recording
reviewed: 2026-09-21T06:45:00Z
depth: standard
files_reviewed: 7
files_reviewed_list:
  - db/migrate/20260921100000_add_title_and_source_to_visited_links.rb
  - app/models/visited_link.rb
  - app/controllers/visited_links_controller.rb
  - app/assets/javascripts/visited_links.js
  - test/models/visited_link_test.rb
  - test/controllers/visited_links_controller_test.rb
  - test/assets/visited_links_js_contract_test.rb
findings:
  critical: 0
  warning: 2
  info: 1
  total: 3
status: issues_found
---

# Phase 131: Code Review Report

**Reviewed:** 2026-09-21T06:45:00Z
**Depth:** standard
**Files Reviewed:** 7
**Status:** issues_found

## Summary

Phase 131 extends feed visit recording end-to-end: migration adds nullable `title`/`source`, `VisitedLink.record!` upserts feed metadata when `source == 'feed'`, the controller gates feed params, and `visited_links.js` detects `feed_` gadget IDs to POST `{ url, title, source: 'feed' }`. Scoped Minitest (34 runs) passes.

The core wiring is sound — feed gadget ID detection matches `Feed#gadget_id`, non-feed paths remain URL-only, and upsert idempotency is covered by model/controller tests. Two robustness gaps remain around title handling: empty titles on re-click erase stored titles (contrary to REC-02 “when provided”), and over-length titles raise `ActiveRecord::ValueTooLong` with no controller rescue (500 response).

## Warnings

### WR-01: Empty feed title on re-click clears stored title

**File:** `app/models/visited_link.rb:10-14`
**Issue:** When `source == 'feed'`, the code always sets `attrs[:title] = stripped_title.presence`. On upsert duplicate-key update, an explicit `nil` title is written to the row, clearing a previously stored headline. Verified via `rails runner`: `"First"` → `""` → `nil`. REC-02 specifies feed title updates only “when provided”; whitespace/empty re-clicks should preserve the existing title.
**Fix:**
```ruby
if source == 'feed'
  attrs[:source] = 'feed'
  stripped_title = title.to_s.strip
  attrs[:title] = stripped_title if stripped_title.present?
end
```

### WR-02: No title length guard before upsert

**File:** `app/models/visited_link.rb:10-16`, `app/controllers/visited_links_controller.rb:2-8`
**Issue:** The migration limits `title` to 2083 characters, but neither the model nor controller truncates or validates length. A title longer than 2083 chars (possible from RSS entries or crafted POST bodies) raises `ActiveRecord::ValueTooLong`, producing a 500 instead of the usual fire-and-forget `204 No Content`. The visit is not recorded and the JS client receives no graceful handling.
**Fix:** Truncate before upsert (mirror URL column limit) or add a length validation and skip title when too long:
```ruby
MAX_TITLE_LENGTH = 2083

stripped_title = title.to_s.strip
if stripped_title.present?
  attrs[:title] = stripped_title.byteslice(0, MAX_TITLE_LENGTH)
end
```

## Info

### IN-01: Missing test for URL-only row upgraded to feed visit

**File:** `test/models/visited_link_test.rb`
**Issue:** Tests cover feed→feed upsert and non-feed source rejection, but not the path where a URL-only row (Mastodon/X click) is later revisited from a feed gadget and should gain `title` + `source='feed'`. Upsert logic likely handles this, but the upgrade path is untested.
**Fix:** Add a test: record URL-only, then `record!(..., title: 'Headline', source: 'feed')`, assert title/source populated without duplicate row.

---

_Reviewed: 2026-09-21T06:45:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
