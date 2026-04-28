---
phase: 06-html-structure
reviewed: 2026-04-29T00:00:00Z
depth: standard
files_reviewed: 2
files_reviewed_list:
  - test/controllers/layout_structure_test.rb
  - app/views/layouts/application.html.erb
findings:
  critical: 0
  warning: 4
  info: 2
  total: 6
status: issues_found
---

# Phase 06: Code Review Report

**Reviewed:** 2026-04-29
**Depth:** standard
**Files Reviewed:** 2
**Status:** issues_found

## Summary

Phase 06 adds a hamburger button to the header and a drawer/overlay HTML structure guarded by `user_signed_in?`. The ERB is straightforward, and the overall structure is sound. However, there are four correctness/reliability problems worth fixing before this ships, and two minor quality items.

The most significant issue is a test assertion that will never pass as written: the CSS selector `[data-method=?]` is applied to a `link_to ... method: 'delete'` that Rails 7 / ActionView 8 renders as `data-method="delete"`, but the test attempts to match the attribute on the `<a>` element — this part is actually fine at the HTML level. What is actually broken is the _structure_ test `test_ドロワーはwrapperの外にあり_bodyの直下にある` combined with the DOM reality: `div.drawer-overlay` lives outside the drawer but is _not_ tested to be a `body` direct child, yet the test passes an implicit assumption about theme-independence while the drawer is theme-gated.

Below are all findings in detail.

---

## Warnings

### WR-01: `test_デフォルトテーマでもハンバーガーボタンが存在する` — hamburger tested without theme guard, but `test_ドロワーはwrapperの外にあり_bodyの直下にある` also runs without theme — drawer is NOT rendered

**File:** `test/controllers/layout_structure_test.rb:44-50`

**Issue:** `test_ドロワーはwrapperの外にあり_bodyの直下にある` signs in without setting `theme: 'modern'`, then asserts `body > div.drawer` count is 1. But the drawer is always rendered when `user_signed_in?` is true — the `if user_signed_in?` guard at line 29 of the layout makes the drawer unconditional on theme. The hamburger button is also rendered unconditionally (line 21). So the test assertion itself is correct, but the test description is misleading: it implies the structure test is theme-independent, which is true. The real concern is the _inverse_ assertion at line 49: `assert_select '.wrapper div.drawer', count: 0` — this correctly passes only if the drawer is NOT nested inside `.wrapper`. This assertion is valid. No code bug here, but there is a **reliability gap**: if a future refactor moves the drawer inside `.wrapper`, this test catches it only for the logged-in-no-theme case, not the modern-theme case, because `test_モダンテーマでドロワーが存在する` (lines 20-27) does not check the placement. Consider adding the placement assertion to the modern-theme test as well.

**Fix:** Add placement check to `test_モダンテーマでドロワーが存在する`:
```ruby
def test_モダンテーマでドロワーが存在する
  user.preference.update!(theme: 'modern')
  sign_in user
  get root_path
  assert_response :success
  assert_select 'body > div.drawer', count: 1
  assert_select 'body > div.drawer-overlay', count: 1
  assert_select '.wrapper div.drawer', count: 0
end
```

---

### WR-02: `div.drawer-overlay` placement not tested as `body` direct child

**File:** `test/controllers/layout_structure_test.rb:44-50`

**Issue:** `test_ドロワーはwrapperの外にあり_bodyの直下にある` verifies `body > div.drawer` (count: 1) and `'.wrapper div.drawer'` (count: 0), but it does not verify `body > div.drawer-overlay`. In the current ERB, `div.drawer-overlay` is placed outside `.wrapper` at the body level (layout line 41), but the test does not assert this. A future change that accidentally nests `div.drawer-overlay` inside `.wrapper` or inside `div.drawer` would go undetected.

**Fix:**
```ruby
def test_ドロワーはwrapperの外にあり_bodyの直下にある
  sign_in user
  get root_path
  assert_response :success
  assert_select 'body > div.drawer', count: 1
  assert_select 'body > div.drawer-overlay', count: 1   # add this
  assert_select '.wrapper div.drawer', count: 0
  assert_select '.wrapper div.drawer-overlay', count: 0  # add this
end
```

---

### WR-03: `test_ドロワーに全ナビリンクが含まれる` — `data-method` assertion uses the wrong attribute value source

**File:** `test/controllers/layout_structure_test.rb:41`

**Issue:** Line 41 asserts:
```ruby
assert_select '.drawer a[href=?][data-method=?]', destroy_user_session_path, 'delete'
```
`link_to ... method: 'delete'` in Rails 7 with `rails-ujs` renders `data-method="delete"` on the anchor. This test assertion is semantically correct and will pass. However, the assertion on line 40 directly above it:
```ruby
assert_select '.drawer a[href=?]', destroy_user_session_path
```
is redundant — line 41 already selects the same `href`. The duplication is harmless but creates false confidence: if the `data-method` assertion were somehow skipped or misconfigured, line 40 would still pass and mask the omission. More importantly, the two-argument form of `assert_select` with `[attr=?]` passes the substituted value in order — **both** `destroy_user_session_path` and `'delete'` map positionally to the two `?` placeholders. This is correct Rails test behaviour, but it is subtle: if a developer swaps the arguments, the test silently produces a wrong selector. The assertion should be accompanied by a comment, or simplified.

**Fix:** Remove the redundant line 40 and keep only line 41, with a comment:
```ruby
# Verify logout link uses data-method="delete" (rails-ujs DELETE verb)
assert_select '.drawer a[href=?][data-method=?]', destroy_user_session_path, 'delete'
```

---

### WR-04: Hamburger button rendered outside the `user_signed_in?` guard — creates orphaned interactive element for guests

**File:** `app/views/layouts/application.html.erb:21`

**Issue:** The `<button class="hamburger-btn" aria-label="メニュー">` (line 21) is rendered unconditionally — it appears for all users including unauthenticated guests. The drawer it controls (lines 30-42) is only rendered when `user_signed_in?`. On the guest sign-in page, the hamburger button will be present in the DOM with no corresponding drawer or overlay to open. When JS wires up click handlers, clicking the button will either throw a JS error or silently do nothing. This is an incorrect state: an interactive control exists for a panel that does not.

**Fix:** Either wrap the hamburger button in the same `user_signed_in?` guard as the drawer, or render it always but hide it via CSS for guests. The cleanest solution is co-location with the drawer guard:
```erb
<div id="header">
  <div class="head-box">
    <img src="/icon.svg" alt="Bookmarks" class="header-icon" />
    Bookmarks
    <% if user_signed_in? %>
      <button class="hamburger-btn" aria-label="メニュー"></button>
    <% end %>
  </div>
</div>
```
The test `test_非ログイン時はドロワーが存在しない` (line 61-64) only checks for a redirect; it does not assert absence of the hamburger. Add an assertion there too:
```ruby
def test_非ログイン時はドロワーが存在しない
  get root_path
  assert_response :redirect
  follow_redirect!
  assert_select 'button.hamburger-btn', count: 0
  assert_select 'div.drawer', count: 0
end
```

---

## Info

### IN-01: `test_デフォルトテーマでもハンバーガーボタンが存在する` — test name implies theme-conditional behaviour, but code is unconditional

**File:** `test/controllers/layout_structure_test.rb:13-18`

**Issue:** The test name reads "even in the default theme the hamburger button exists," implying the button's presence varies by theme. However, the button is always rendered (layout line 21), with no theme check at all. The test name creates the false impression that there is theme-gated logic to verify. This may confuse future readers.

**Fix:** Rename to better reflect intent, e.g.:
```ruby
def test_ハンバーガーボタンはテーマに関わらず表示される
```
Or, if the intent really is to document theme-independence, also assert that it is absent for guests.

---

### IN-02: `favorite_theme` can return `nil` — body class becomes `class=""`

**File:** `app/views/layouts/application.html.erb:16`

**Issue:** `favorite_theme` returns `nil` when the user is not signed in or has no preference (helper lines 4-5). ERB's `<%= nil %>` outputs an empty string, so the body tag becomes `<body class="">`. This is not a crash, but it is slightly dirty HTML and may cause unexpected CSS selector issues (`body.""` is invalid, though `body[class=""]` selects correctly). The `body` has no semantic class when a guest visits.

**Fix:** Use `presence` or a default value:
```erb
<body class="<%= favorite_theme.presence %>">
```
Or provide a fallback:
```erb
<body class="<%= favorite_theme || 'default' %>">
```

---

_Reviewed: 2026-04-29_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
