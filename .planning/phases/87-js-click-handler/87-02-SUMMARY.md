---
phase: 87-js-click-handler
plan: "02"
subsystem: cucumber
tags: [visited-links, cucumber, e2e, webmock, capybara]
dependency_graph:
  requires: [87-01]
  provides: [features/08.訪問済みリンク.feature, features/step_definitions/visited_links.rb]
  affects: [features/support/hooks.rb]
tech_stack:
  added: []
  patterns: [Cucumber delegated-event E2E, WebMock override (last-registered wins), Capybara capture-phase intercept]
key_files:
  created:
    - features/08.訪問済みリンク.feature
    - features/step_definitions/visited_links.rb
  modified:
    - features/support/hooks.rb
decisions:
  - WebMock exact-URL stub registered after global /slashdot/ regex stub — last-registered wins
  - capture-phase addEventListener (third arg `true`) intercepts navigation without stopping click bubble
  - assert_selector wait:15 for AJAX-injected gadget content consistent with mastodon step convention
  - has_css? default wait sufficient for synchronous addClass (no extra wait needed)
metrics:
  duration: "~10 minutes"
  completed: "2026-05-18"
  tasks_completed: 2
  tasks_total: 2
---

# Phase 87 Plan 02: Cucumber E2E Scenario for Visited Link Click Flow Summary

**One-liner:** Cucumber E2E scenario proves delegated click handler fires on AJAX-injected gadget links and adds `.link--visited` synchronously.

## What Was Built

### `features/support/hooks.rb` (appended)
Added `Before('@feed_visited_links')` and `After('@feed_visited_links')` blocks:
- Before: registers exact-URL WebMock stub for `http://slashdot.jp/slashdotjp.rss` with one `<item>` (title: "Stub Article", link: "https://example.com/stub-article"). Exact URL takes priority over global `/slashdot/` regex stub (WebMock: last-registered wins).
- After: removes the stub via `WebMock.remove_request_stub`.

### `features/08.訪問済みリンク.feature`
One scenario tagged `@feed_visited_links`:
- Signs in with modern theme
- Opens root page
- Waits for AJAX-injected "Stub Article" link (`wait: 15`)
- Installs capture-phase navigation intercept via `execute_script`
- Clicks the first gadget link
- Asserts `.link--visited` class is present

### `features/step_definitions/visited_links.rb`
Four Japanese step definitions:
1. `フィードガジェットに "..." が表示される` — `assert_selector` with `wait: 15`
2. `ガジェットリンクのナビゲーションを抑制します。` — `execute_script` capture-phase intercept
3. `フィードガジェットの最初のリンクをクリックします。` — `find(..., match: :first).click`
4. `そのリンクに "..." クラスが付与されています。` — `assert has_css?` (synchronous)

## Verification Results

| Check | Result |
|-------|--------|
| `bundle exec rake dad:test` | ✅ 25 passed (new scenario included), 1 pre-existing failure in 02.タスク.feature |
| Pre-existing failure confirmed | ✅ Same failure present without Wave 2 changes (stash-verified) |

## Pre-existing Failure Note

`features/02.タスク.feature:11` (シナリオ: タスク追加時の初期優先度を設定する) fails in both baseline and after Wave 2 changes — confirmed pre-existing, not caused by this plan.

## Commits

| Hash | Message |
|------|---------|
| 5214710 | feat(87-02): add Cucumber E2E scenario for visited link click flow |

## Deviations from Plan

None — plan executed exactly as written.

## Self-Check: PASSED
- `features/08.訪問済みリンク.feature` — exists ✅
- `features/step_definitions/visited_links.rb` — exists ✅
- `features/support/hooks.rb` contains `feed_visited_links` (2 occurrences) ✅
- Commit 5214710 — exists ✅
