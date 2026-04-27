---
phase: "01"
plan: "01"
subsystem: bookmarks
tags: [auto-title, faraday, nokogiri, jquery, sprockets]
dependency_graph:
  requires: []
  provides: [bookmarks#fetch_title, bookmarks.js]
  affects: [config/routes.rb, app/controllers/bookmarks_controller.rb, app/assets/javascripts/bookmarks.js]
tech_stack:
  added: []
  patterns: [server-side proxy, event delegation blur handler]
key_files:
  created:
    - app/assets/javascripts/bookmarks.js
  modified:
    - config/routes.rb
    - app/controllers/bookmarks_controller.rb
decisions:
  - Use $(document).ready instead of turbolinks:load (Turbolinks not in application.js manifest)
  - Authentication delegated to ApplicationController#authenticate_user! (no extra before_action needed)
  - rescue StandardError covers all error cases including network, parse, and explicit raises
metrics:
  duration: "~10 minutes"
  completed: "2026-04-27"
  tasks_completed: 4
  files_changed: 3
---

# Phase 1 Plan 01: Automatic Title Scrape for New Bookmark Summary

**One-liner:** Server-side Faraday+Nokogiri proxy at GET /bookmarks/fetch_title auto-fills the bookmark title field on URL blur via jQuery event delegation.

## What Was Done

### Task 1: Add route (commit 691fbd3)
Added a `collection` block to `resources :bookmarks` in `config/routes.rb` with `get 'fetch_title'`, creating the route `GET /bookmarks/fetch_title => bookmarks#fetch_title`. Mirrors the existing `resources :feeds` pattern.

### Task 2: Add controller action (commit ab0c15b)
Added `BookmarksController#fetch_title` before the `private` keyword. The action:
- Strips and validates the `url` query param (raises `ArgumentError` if blank)
- Opens a Faraday connection with 5s timeout and follow-redirects middleware
- Parses the response body with Nokogiri to extract the `<title>` tag text
- Returns the title as `render plain: title`
- Catches all `StandardError` (network errors, timeouts, parse errors, blank title) with `head :ok` (empty 200)

No extra `before_action :authenticate_user!` was needed — `ApplicationController` already declares it globally.

### Task 3: Create bookmarks.js (commit 28750fc)
Created `app/assets/javascripts/bookmarks.js` with:
- `$(document).ready` wrapper (Turbolinks not present in application.js)
- Event delegation on `document` for `blur` on `#bookmark_url`
- GET request to `/bookmarks/fetch_title?url=<value>` on non-empty URL blur
- Pre-fills `#bookmark_title` only when that field is currently empty
- Silent `.fail()` handler

### Task 4: Verify asset pipeline (no commit — read-only)
Confirmed `application.js` already contains `//= require_tree .` on line 17. No manual `//= require bookmarks` was added — doing so alongside `require_tree .` would cause double-inclusion.

## Deviations from Plan

None — plan executed exactly as written.

The plan noted two possible implementations for the JS lifecycle event (`turbolinks:load` vs `$(document).ready`) and directed use of `$(document).ready` when Turbolinks is absent from the manifest. `application.js` confirms Turbolinks is not required, so `$(document).ready` was used as directed.

## Known Stubs

None.

## Threat Flags

| Flag | File | Description |
|------|------|-------------|
| threat_flag: ssrf | app/controllers/bookmarks_controller.rb | fetch_title accepts arbitrary user-supplied URLs and makes server-side HTTP requests — potential SSRF if internal network is accessible from the server |

## Self-Check: PASSED

- config/routes.rb modified: FOUND
- app/controllers/bookmarks_controller.rb modified: FOUND
- app/assets/javascripts/bookmarks.js created: FOUND
- commit 691fbd3 (route): FOUND
- commit ab0c15b (controller): FOUND
- commit 28750fc (JS): FOUND
