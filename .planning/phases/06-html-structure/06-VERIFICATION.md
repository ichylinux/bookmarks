---
phase: 06-html-structure
verified: 2026-04-29T03:00:00Z
status: human_needed
score: 8/8 must-haves verified
overrides_applied: 0
re_verification: false
human_verification:
  - test: "Open the app in a browser with modern theme active and visually confirm the hamburger button appears in the header area"
    expected: "A button is visible in the right side of the header bar when body.modern is active"
    why_human: "SC-1 says 'a hamburger button element is visible in the header area' — visibility depends on Phase 7 CSS (not yet written); the HTML is present but whether it renders visibly is a CSS concern. Programmatic verification confirms the element exists in the DOM, not that it is visible to a real user."
  - test: "Open the app with a non-modern theme active, trigger the existing dropdown menu, and confirm it opens and dismisses normally"
    expected: "The dropdown nav and its inline <script> continue to function; no regression from Phase 6 changes"
    why_human: "SC-4 requires that the existing dropdown menu interaction still works. The _menu.html.erb file is verified byte-identical to its pre-Phase-6 state by git log, but interaction correctness (click-to-open, click-to-dismiss) cannot be verified without a browser."
---

# Phase 06: HTML Structure Verification Report

**Phase Goal:** The hamburger button and drawer markup exist in the DOM under the modern theme, correctly positioned so drawer can slide in without clipping
**Verified:** 2026-04-29T03:00:00Z
**Status:** human_needed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Hamburger button (`button.hamburger-btn[aria-label="メニュー"]`) exists as last child of `.head-box`, body empty, unconditional | VERIFIED | `application.html.erb` line 21: `<button class="hamburger-btn" aria-label="メニュー"></button>` is the last element inside `.head-box` (lines 18-22); not gated on `user_signed_in?` |
| 2 | `div.drawer` and `div.drawer-overlay` are direct children of `<body>`, placed after `</div>` closing `.wrapper`, inside `user_signed_in?` guard | VERIFIED | Lines 28-42 of `application.html.erb`: `</div>` closes `.wrapper` at line 28; `<% if user_signed_in? %>` begins at line 29; `div.drawer` at line 30; `div.drawer-overlay` at line 41; `</body>` at line 43 |
| 3 | `div.drawer` contains exactly 7 `<a>` elements via a `<nav>` child, in order matching `_menu.html.erb` | VERIFIED | Lines 31-39: `<nav>` wraps 7 `link_to` calls (Home, 設定, ブックマーク, タスク, カレンダー, フィード, ログアウト) — exact order matches `_menu.html.erb` lines 35-44 |
| 4 | Logout link inside drawer uses `method: 'delete'` (Rails UJS form spoofing for Devise sign-out) | VERIFIED | `application.html.erb` line 38: `<%= link_to 'ログアウト', destroy_user_session_path, method: 'delete' %>` |
| 5 | Drawer and overlay are NOT rendered when no user is signed in | VERIFIED | Both elements are inside `<% if user_signed_in? %>` guard (line 29); test `test_非ログイン時はドロワーが存在しない` confirms unauthenticated GET / returns :redirect |
| 6 | `app/views/common/_menu.html.erb` is unchanged from its pre-Phase-6 state | VERIFIED | `git log -- app/views/common/_menu.html.erb` shows last commit is `c7c75c0` (pre-Phase-6); the file still contains its inline `<script>` (line 2) and all 6 nav links + logout (lines 35-44) |
| 7 | All 7 LayoutStructureTest integration tests pass (GREEN) | VERIFIED | `bundle exec ruby -Itest test/controllers/layout_structure_test.rb` → `7 runs, 33 assertions, 0 failures, 0 errors, 0 skips` |
| 8 | No partial `_drawer.html.erb` was created (D-06 decision: inline, no shared partial) | VERIFIED | Drawer links are inline in `application.html.erb`; no `_drawer.html.erb` file exists in `app/views/` |

**Score:** 8/8 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `test/controllers/layout_structure_test.rb` | Integration tests for hamburger + drawer + overlay structure | VERIFIED | File exists; `class LayoutStructureTest < ActionDispatch::IntegrationTest`; 7 test methods with Japanese names; all pass |
| `app/views/layouts/application.html.erb` | Updated layout with hamburger in `.head-box` and drawer+overlay after `.wrapper` | VERIFIED | Contains `hamburger-btn`, `div.drawer`, `div.drawer-overlay`; +15 lines added at commit `75d8359` |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `application.html.erb` | `div.head-box` | `button.hamburger-btn` appended as last child | WIRED | Line 21: `<button class="hamburger-btn" aria-label="メニュー"></button>` is final element before `</div>` at line 22 |
| `application.html.erb` | `<body>` | `div.drawer` + `div.drawer-overlay` placed after `</div>.wrapper`, before `</body>`, inside `if user_signed_in?` | WIRED | Lines 29-42: guard starts immediately after `.wrapper` closes at line 28; both elements are direct body children |
| `div.drawer > nav` | Rails path helpers | `link_to` calls mirroring `_menu.html.erb` (7 links, logout uses `method: 'delete'`) | WIRED | All 7 path helpers present; `method: 'delete'` on logout confirmed at line 38 |

### Data-Flow Trace (Level 4)

Not applicable. Phase 6 is a pure HTML/ERB structural change — no dynamic data rendering, no state variables, no fetch/query calls. The only conditional is `user_signed_in?` (Devise auth guard), which is verified by the test suite.

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| All 7 LayoutStructureTest tests pass | `bundle exec ruby -Itest test/controllers/layout_structure_test.rb` | `7 runs, 33 assertions, 0 failures, 0 errors, 0 skips` | PASS |
| Hamburger button in layout | `grep -c 'hamburger-btn' app/views/layouts/application.html.erb` | `2` (class attr + aria-label on same line) | PASS |
| Drawer element present | `grep -c 'class="drawer"' app/views/layouts/application.html.erb` | `1` | PASS |
| Drawer-overlay present | `grep -c 'drawer-overlay' app/views/layouts/application.html.erb` | `1` | PASS |
| Logout `method: 'delete'` | `grep -c "method: 'delete'" app/views/layouts/application.html.erb` | `1` | PASS |
| `_menu.html.erb` unmodified | `git log --oneline -1 -- app/views/common/_menu.html.erb` | `c7c75c0` (pre-Phase-6 commit) | PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|-------------|-------------|--------|----------|
| NAV-01 | 06-01-PLAN.md | User sees a hamburger button in the header when using the modern theme | SATISFIED | `button.hamburger-btn[aria-label="メニュー"]` is unconditionally in `.head-box`; Phase 7 CSS will control visibility via `body.modern` scope. Structural prerequisite fully delivered. |
| NAV-02 | 06-01-PLAN.md | User can open a side drawer containing all navigation links by clicking the hamburger | PARTIAL — structural prerequisite delivered; JS wiring is Phase 8 | `div.drawer` with all 7 nav links exists in DOM. Click interaction requires Phase 8 JS. REQUIREMENTS.md traceability explicitly maps NAV-02 to "Phase 6, 8" — Phase 6's portion is the HTML scaffold, which is complete. |

**Note on NAV-02:** REQUIREMENTS.md maps NAV-02 to Phase 6 AND Phase 8. Phase 6's contractual scope is the HTML scaffold (drawer + links exist in DOM). Phase 8 delivers the JS click wiring. The Phase 6 portion of NAV-02 is satisfied. The Phase 8 portion is deferred by design.

**Note on ROADMAP checklist wording:** The milestone overview line says "add drawer div and overlay div with all nav links to `_menu.html.erb` outside `.wrapper`". The authoritative Phase 6 Details section and the PLAN both specify `application.html.erb` (which is correct — `_menu.html.erb` is a partial rendered inside `.wrapper`, so the drawer cannot be placed there without being inside `.wrapper`). The implementation correctly targets `application.html.erb`. The checklist wording is a typo in the milestone summary.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| None | — | — | — | — |

No stubs, TODO comments, placeholder text, empty handlers, or hardcoded empty data found in either modified file.

### Human Verification Required

#### 1. Hamburger button visual presence (SC-1)

**Test:** Sign in with modern theme active. Navigate to the root page. Look at the header area.
**Expected:** A button is visible in the header bar (right side of `.head-box`). Since Phase 7 CSS has not been written yet, the button may render as a zero-dimension invisible element — but it must be present in the DOM (confirmed) and Phase 7 will make it visible.
**Why human:** "Visible in the header area" is a visual/CSS concern. The HTML element is verified to exist in the DOM. Actual visibility requires Phase 7 CSS. This check confirms no layout-breaking side effects from the unconditional button insertion.

#### 2. Existing dropdown menu functional regression (SC-4)

**Test:** Sign in with a non-modern theme (default). Click the existing dropdown nav trigger. Confirm the menu opens. Click outside to dismiss. Confirm it closes.
**Expected:** The existing dropdown and its inline `<script>` in `_menu.html.erb` continue to work exactly as before Phase 6.
**Why human:** `_menu.html.erb` is verified byte-identical to its pre-Phase-6 state by git log (no commits touch the file in Phase 6). However, the interaction behavior (jQuery click handlers in the inline `<script>`) cannot be verified programmatically without running a browser.

## Gaps Summary

No gaps found. All 8 observable truths are VERIFIED. The 2 human verification items are confirmatory checks on visual appearance and existing interaction behavior — not blockers, since the HTML structure is fully verified programmatically.

The phase goal — "hamburger button and drawer markup exist in the DOM under the modern theme, correctly positioned so drawer can slide in without clipping" — is achieved in the codebase.

---

_Verified: 2026-04-29T03:00:00Z_
_Verifier: Claude (gsd-verifier)_
