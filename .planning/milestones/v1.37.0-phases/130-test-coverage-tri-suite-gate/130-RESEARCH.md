# Phase 130: Test Coverage & Tri-Suite Gate - Research

**Researched:** 2026-06-26
**Domain:** Rails Minitest CSS contract tests + Cucumber @mobile_portal E2E scenarios
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- TEST-01: Minitest asserts `welcome.css.scss` contains `@media (hover: none)` block with `.todo-gadget-new-link` at `opacity: 1` and `pointer-events: auto`
- TEST-02: Cucumber `@mobile_portal` scenario at 390px viewport: visits welcome page, taps "追加" link, fills title field, submits form, asserts new todo appears in gadget list
- TEST-03: The step that navigates to the welcome page MUST call `ensure_mobile_viewport!` before `visit root_path` — `@mobile_portal` tag alone does not resize
- TEST-03: `yarn run lint && bin/rails test && bundle exec rake dad:test` all exit 0 with 0 failures

### Claude's Discretion
All implementation choices are at Claude's discretion — this is a pure test infrastructure phase. Use ROADMAP phase goal, success criteria, and codebase conventions to guide decisions.

### Deferred Ideas (OUT OF SCOPE)
None — this phase covers all TEST requirements (TEST-01, TEST-02, TEST-03).
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| TEST-01 | Minitest asserts `welcome.css.scss` contains `@media (hover: none)` block with `.todo-gadget-new-link` at `opacity: 1` and `pointer-events: auto` | CSS structure confirmed in file; test pattern established by `mobile_responsive_contract_test.rb` |
| TEST-02 | Cucumber `@mobile_portal` scenario at 390px: visits welcome page, taps "追加" link, fills title, submits, asserts new todo appears | All required step definitions already exist; no new definitions needed |
| TEST-03 | Step navigating to welcome page explicitly calls `ensure_mobile_viewport!` before `visit root_path`; full tri-suite gate green | `ルートページを開きます。` in `modern_theme.rb` already satisfies this; globally available to all feature files |
</phase_requirements>

## Summary

Phase 130 adds two automated tests to verify the mobile CSS changes from Phase 129: one Minitest CSS structure test and one Cucumber E2E scenario. Both fit naturally into the existing test infrastructure with minimal new code.

The Minitest test follows the exact pattern established by `test/assets/mobile_responsive_contract_test.rb` — reads a stylesheet as a string and uses `assert_match` with regex. The target file is `welcome.css.scss`, which Phase 129 added an `@media (hover: none)` block to at lines 319–325. [ASSUMED: lines approximate; exact line numbers should be verified from the file before writing assertions]

The Cucumber scenario can be added to the existing `features/02.タスク.feature` with a `@mobile_portal` tag and reuse all three required step definitions already in the codebase: `設定画面で タスクを表示する にチェックを入れます。` (signs in + enables use_todo), `ルートページを開きます。` (calls `ensure_mobile_viewport!` then `visit root_path`), and `追加 をクリックしてタスクを追加します。` (JS-clicks link, fills form, submits, asserts count). No new step definitions are required.

**Primary recommendation:** Add one file (`test/assets/todo_gadget_mobile_css_contract_test.rb`) and extend one feature file (`features/02.タスク.feature`) with a single tagged scenario.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| CSS structure verification | Test (Minitest) | — | File-read test; no browser or DB needed |
| Mobile E2E interaction | Test (Cucumber/Selenium) | Frontend (mobile CSS) | Requires headless Chrome at 390px to verify tap behavior |
| Viewport management | Test support (`window_resize.rb`) | — | `ensure_mobile_viewport!` already owns this concern |
| Preference setup | Test step definitions (`todos.rb`) | — | Existing step handles sign-in + use_todo toggle |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Minitest | bundled with Rails 7.2 | Unit test framework | Project-standard; all `test/assets/` tests use it |
| Cucumber / cucumber-rails | bundled via daddy gem | E2E browser tests | Project-standard; `bundle exec rake dad:test` |
| Capybara + Selenium | bundled via daddy/cucumber-rails | Browser automation | Standard driver for `dad:test` scenarios |

[ASSUMED: exact gem versions not verified this session; check Gemfile.lock if version-specific behaviour is a concern]

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `closer` gem (via `daddy`) | 0.18.3 | Provides `capture` and `with_capture` screenshot helpers | Used in every Cucumber step definition |
| WebMock | bundled | HTTP stub library | Only needed when the scenario triggers external API calls — not required here |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Adding scenario to `02.タスク.feature` | New file `15.モバイルタスク.feature` | New file adds overhead without benefit; the `@mobile_portal` tag provides clear separation within the existing feature |
| Reusing `ルートページを開きます。` from `modern_theme.rb` | Writing a new todo-specific step | Duplication; the existing step already satisfies TEST-03 exactly |

## Architecture Patterns

### System Architecture Diagram

```
Minitest (bin/rails test)
  └── test/assets/todo_gadget_mobile_css_contract_test.rb
        └── File.read → welcome.css.scss
              └── assert_match → @media (hover: none) { .todo-gadget-new-link { opacity: 1; pointer-events: auto; } }

Cucumber (bundle exec rake dad:test)
  └── features/02.タスク.feature  [@mobile_portal scenario]
        ├── Step: 設定画面で タスクを表示する にチェックを入れます。
        │     └── sign_in(user) → visit /preferences → check 'タスクを表示する' → save
        ├── Step: ルートページを開きます。   [defined in modern_theme.rb]
        │     └── ensure_mobile_viewport!  →  resize_browser_window(390, 844)
        │     └── visit root_path          →  #todo gadget in DOM (use_todo=true)
        └── Step: 追加 をクリックしてタスクを追加します。
              ├── JS click .todo-gadget-new-link → todos.new_todo() → form.todo rendered
              ├── fill_in 'todo[title]' → '新しいタスクの内容'
              ├── click_on '登録'        → POST /todos
              └── assert find('#todo').all('li', count: @todo_count + 1)
```

### Recommended Project Structure

No new directories needed. Files slot into existing locations:

```
test/
└── assets/
    └── todo_gadget_mobile_css_contract_test.rb   # NEW — TEST-01

features/
├── 02.タスク.feature                              # EXTEND — add @mobile_portal scenario
└── step_definitions/
    └── modern_theme.rb                            # UNCHANGED — provides ルートページを開きます。
    └── todos.rb                                   # UNCHANGED — provides both reused steps
```

### Pattern 1: CSS Structure Contract Test (Minitest)

All existing `test/assets/*_contract_test.rb` files follow this pattern. [VERIFIED: codebase — `mobile_responsive_contract_test.rb`, `css_architecture_contract_test.rb`, `portal_mobile_tabs_js_contract_test.rb`]

```ruby
# Source: test/assets/mobile_responsive_contract_test.rb (codebase)
require 'test_helper'

class TodoGadgetMobileCssContractTest < ActiveSupport::TestCase
  def setup
    @welcome = Rails.root.join('app/assets/stylesheets/welcome.css.scss').read
  end

  test 'welcome.css.scss contains hover-none media block for todo-gadget-new-link' do
    assert_match(
      /@media\s*\(\s*hover\s*:\s*none\s*\)[\s\S]*?\.todo-gadget-new-link/,
      @welcome,
      'welcome.css.scss must contain @media (hover: none) { .todo-gadget-new-link { ... } }. MOB-01 override is missing.'
    )
  end

  test 'welcome.css.scss todo-gadget-new-link has opacity 1 inside hover-none block' do
    assert_match(
      /@media\s*\(\s*hover\s*:\s*none\s*\)[\s\S]*?\.todo-gadget-new-link[\s\S]*?opacity\s*:\s*1/,
      @welcome,
      'welcome.css.scss must set opacity: 1 on .todo-gadget-new-link inside @media (hover: none). MOB-01.'
    )
  end

  test 'welcome.css.scss todo-gadget-new-link has pointer-events auto inside hover-none block' do
    assert_match(
      /@media\s*\(\s*hover\s*:\s*none\s*\)[\s\S]*?\.todo-gadget-new-link[\s\S]*?pointer-events\s*:\s*auto/,
      @welcome,
      'welcome.css.scss must set pointer-events: auto on .todo-gadget-new-link inside @media (hover: none). MOB-01.'
    )
  end
end
```

### Pattern 2: @mobile_portal Cucumber Scenario

The tag `@mobile_portal` and helper `ensure_mobile_viewport!` are already fully wired. [VERIFIED: codebase — `features/support/window_resize.rb`, `features/03.モダンテーマ.feature`]

**Hook lifecycle (already defined in `window_resize.rb`):**
```ruby
# Source: features/support/window_resize.rb (codebase)
Before('@mobile_portal') do
  @mobile_portal_scenario = true
end

def ensure_mobile_viewport!
  return unless @mobile_portal_scenario
  resize_browser_window(390, 844)   # iPhone 12 Pro dimensions
end

After('@mobile_portal') do
  @mobile_portal_scenario = false
  resize_browser_window(1280, 800)  # restore desktop size
end
```

**The step that satisfies TEST-03 (already defined in `modern_theme.rb`):**
```ruby
# Source: features/step_definitions/modern_theme.rb (codebase)
もし /^ルートページを開きます。$/ do
  ensure_mobile_viewport!   # <-- called BEFORE visit, satisfying TEST-03
  visit root_path
  capture
end
```

**The new scenario to add to `features/02.タスク.feature`:**
```gherkin
  @mobile_portal
  シナリオ: モバイルで「追加」リンクをタップしてタスクを追加できる
    * 設定画面で タスクを表示する にチェックを入れます。
    * ルートページを開きます。
    * 追加 をクリックしてタスクを追加します。
```

**Why no new step definitions are needed:**

| Step | File | What it does |
|------|------|-------------|
| `設定画面で タスクを表示する にチェックを入れます。` | `todos.rb` | `sign_in user` → `/preferences` → check `タスクを表示する` → save |
| `ルートページを開きます。` | `modern_theme.rb` | `ensure_mobile_viewport!` then `visit root_path` |
| `追加 をクリックしてタスクを追加します。` | `todos.rb` | JS-clicks new link, fills `todo[title]`, clicks `登録`, asserts count+1 |

### Pattern 3: Existing `click_todo_gadget_new_link` helper

```ruby
# Source: features/step_definitions/todos.rb (codebase)
def click_todo_gadget_new_link
  el = find('#todo .todo-gadget-new-link', visible: :all)
  page.execute_script('arguments[0].click()', el)
end
```

The `visible: :all` finds the link even when opacity:0 (desktop hover state). The `execute_script` click fires the `onclick` handler `todos.new_todo(this)`. On mobile at 390px, the link has `opacity: 1` and `pointer-events: auto` — a regular `.click` would also work, but the existing JS-click path is safe and correct.

### Anti-Patterns to Avoid
- **Using `bundle exec cucumber` directly:** The project requires `bundle exec rake dad:test` — the rake task spawns the Rails server and Chrome headlessly.
- **Adding a `Before(@mobile_portal)` hook for the todo scenario:** The hook already exists in `window_resize.rb`; adding another conflicts.
- **Visiting root before calling `ensure_mobile_viewport!`:** Chrome reports the new viewport only for the subsequent navigation; if root is visited before resize, the rendering uses the old width.
- **Using `visible: :all` on `fill_in`:** `fill_in 'todo[title]', with: '...'` does not support `visible:` — it accepts `exact:` and `match:`. Use default (visible).
- **Asserting opacity via Capybara:** CSS `opacity` is not a Capybara visibility concern; do not try to assert it through Selenium's `visible:` checks. The Minitest CSS structure test verifies the declaration; the Cucumber scenario verifies the behavior.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Viewport resize | Custom JS to set window size | `resize_browser_window(390, 844)` via `window_resize.rb` | Already handles driver edge cases; resets after scenario |
| Mobile tag lifecycle | Custom Before/After hooks | Existing `@mobile_portal` hooks in `window_resize.rb` | Leak prevention already handled |
| CSS assertion | String.include? checks | `assert_match(regex, ...)` | Regex tolerates whitespace variation in SCSS output |
| Screenshot on failure | Manual save_screenshot | `with_capture` + `capture` | Provided by `closer` gem, already integrated |

**Key insight:** Every piece of infrastructure for this phase already exists. The deliverables are one new test file and three new lines in an existing feature file.

## Common Pitfalls

### Pitfall 1: `ルートページを開きます。` defined in `modern_theme.rb` is global
**What goes wrong:** Developer looks for a "todo-specific" step for visiting root and doesn't find one, so they write a new duplicate step `モバイルでルートページを開きます。` in `todos.rb`. Cucumber then has two matching step definitions.
**Why it happens:** Step definitions live in separate files but are loaded globally; the step "ルートページを開きます。" is not obvious to find in `modern_theme.rb`.
**How to avoid:** Use the existing step exactly as written. Cucumber raises `Cucumber::Ambiguous` if two regexes match the same step text.
**Warning signs:** Running `bundle exec rake dad:test` raises `Ambiguous step definitions`.

### Pitfall 2: Regex too broad / lazy quantifier crossing media block boundary
**What goes wrong:** A lazy `[\s\S]*?` in the regex matches across the closing `}` of the hover:none block and into a subsequent rule, causing a false positive (or false negative if a later rule also mentions opacity).
**Why it happens:** SCSS files have multiple blocks; lazy matching can still traverse closing braces.
**How to avoid:** Keep the regex assertion simple — assert the hover:none block exists AND contains the property. Two separate assertions (one per property) are clearer than one complex regex. The existing `mobile_responsive_contract_test.rb` uses this two-assertion pattern.
**Warning signs:** Test passes even after manually removing the opacity rule from the file.

### Pitfall 3: `use_todo` is off by default after `reset_preferences_via_browser!`
**What goes wrong:** The mobile scenario visits root without enabling use_todo, so `#todo` is absent from the DOM and `find('#todo').all('li').size` raises `Capybara::ElementNotFound`.
**Why it happens:** `reset_preferences_via_browser!` (called during `sign_in`) unchecks `use_todo` (line 37 of `preferences_reset.rb`). The user fixture's preferences table does not have `use_todo: true`.
**How to avoid:** Always place `設定画面で タスクを表示する にチェックを入れます。` as the FIRST step so use_todo is enabled before `ルートページを開きます。`.
**Warning signs:** `Capybara::ElementNotFound: Unable to find css "#todo"`.

### Pitfall 4: Portal column layout puts `#todo` in column 1 (visually shifted at 390px)
**What goes wrong:** Developer worries that `fill_in 'todo[title]'` will fail because the todo gadget is in column 1 (shifted off-screen via CSS `transform`).
**Why it happens:** With no explicit `PortalLayout`, the portal distributes bookmark→col0, todo→col1, calendar→col2. At 390px, only col0 is visually active.
**How to avoid:** CSS `transform` and `overflow: hidden` do NOT mark elements as `display: none`. Selenium's `isDisplayed()` still returns true; `fill_in` and `click_on` work normally. The existing `追加 をクリックしてタスクを追加します。` step already uses `visible: :all` for the link and plain Capybara calls for the form — both work in shifted columns.
**Warning signs:** If this does fail, it manifests as `Selenium::WebDriver::Error::ElementNotInteractableError`. Mitigation: click the 2nd portal column tab first (`2列目のポータル列タブをクリックします。`).

### Pitfall 5: WebMock blocking unexpected requests on welcome page load
**What goes wrong:** Visiting root_path triggers a WebMock `NetConnectNotAllowedError` because some gadget makes an external HTTP call not accounted for.
**Why it happens:** If a feed or Mastodon gadget is visible for the test user, it might trigger HTTP requests.
**How to avoid:** The test user fixture has no feeds, no Mastodon accounts, and no X accounts (these are cleaned in `Before` hooks). The welcome page for this user only shows bookmark, todo, and calendar gadgets — none make external HTTP calls on page load.
**Warning signs:** `WebMock::NetConnectNotAllowedError` during the `ルートページを開きます。` step.

## Code Examples

### Actual CSS being tested (from `welcome.css.scss`)

```scss
// Source: app/assets/stylesheets/welcome.css.scss (codebase, lines ~319-325)

// MOB-01: On touch-only devices, the todo gadget "追加" link must be visible and tappable.
// Bookmark new-link opens a dialog and is intentionally excluded from this override.
@media (hover: none) {
  .todo-gadget-new-link {
    opacity: 1;
    pointer-events: auto;
  }
}
```

### Full existing step: `追加 をクリックしてタスクを追加します。`

```ruby
# Source: features/step_definitions/todos.rb (codebase)
もし /^(.*?) をクリックしてタスクを追加します。$/ do |action|
  with_capture do
    assert has_selector?('#todo .todo-gadget-new-link', visible: :all)

    @todo_count = find('#todo').all('li').size

    within '#todo' do
      click_todo_gadget_new_link
    end
    assert has_selector?('form.todo')
    capture

    within 'form.todo' do
      fill_in 'todo[title]', with: '新しいタスクの内容'
      capture
      click_on '登録'
    end

    assert find('#todo').all('li', count: @todo_count + 1)
  end
end
```

The `fill_in 'todo[title]'` targets the `input[name="todo[title]"]` field rendered by `_form.html.erb`. The submit button text `登録` comes from `ja.yml` key `todos.form.create`.

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Direct ActiveRecord writes in Cucumber hooks for preference changes | Browser-driven `/preferences` UI submissions | 2026-05-19 (bce47df) | Eliminates cross-connection snapshot failures; `dad:test` is consistently green |

**Note on suite counts:** The STATE.md records v1.36.0 close at `dad:test` 39/39. Adding one new Cucumber scenario brings the expected count to **40 scenarios**.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | CSS `transform` on `.portal-track` does not prevent Selenium from interacting with elements in shifted columns; `fill_in` and `click_on` will work without navigating to the active column | Pitfall 4 / Common Pitfalls | If wrong: `Selenium::WebDriver::Error::ElementNotInteractableError` in the mobile scenario; mitigation is to add a column-navigation step |

**All other claims in this research were verified against the codebase in this session.**

## Open Questions

1. **Does Selenium's element interactability allow `click_on '登録'` inside a CSS-transformed column?**
   - What we know: CSS `transform` is not in Selenium's visibility algorithm; `display:none` and `visibility:hidden` are; `overflow:hidden` on a parent is not.
   - What's unclear: Whether Chrome's headless driver enforces viewport intersection for `click` events.
   - Recommendation: Implement as planned; if the `click_on '登録'` step raises `ElementNotInteractableError`, add `2列目のポータル列タブをクリックします。` before the 追加 step.

## Environment Availability

Step 2.6: SKIPPED — this phase is code/test-only changes. All external dependencies (Chrome, bundler, rails server) are managed by `bundle exec rake dad:test` and confirmed green at v1.36.0 close (STATE.md).

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | Minitest (Rails 7.2 built-in) + Cucumber (via daddy/cucumber-rails) |
| Config file | `test/test_helper.rb` (Minitest); `features/support/env.rb` (Cucumber) |
| Quick run command | `bin/rails test test/assets/todo_gadget_mobile_css_contract_test.rb` |
| Full suite command | `yarn run lint && bin/rails test && bundle exec rake dad:test` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| TEST-01 | `welcome.css.scss` contains `@media (hover: none)` with `.todo-gadget-new-link` opacity:1 and pointer-events:auto | Unit (CSS contract) | `bin/rails test test/assets/todo_gadget_mobile_css_contract_test.rb` | ❌ Wave 0 |
| TEST-02 | Mobile scenario: 390px viewport, tap 追加, fill form, submit, assert todo appears | E2E (Cucumber) | `bundle exec rake dad:test` | ❌ Wave 0 (scenario added to existing file) |
| TEST-03 | `ensure_mobile_viewport!` called before `visit root_path` in the navigation step | E2E (Cucumber, structural) | `bundle exec rake dad:test` | ✅ (satisfied by existing `ルートページを開きます。` step) |

### Sampling Rate
- **Per task commit:** `bin/rails test test/assets/todo_gadget_mobile_css_contract_test.rb`
- **Per wave merge:** `bin/rails test && bundle exec rake dad:test`
- **Phase gate:** `yarn run lint && bin/rails test && bundle exec rake dad:test` all exit 0

### Wave 0 Gaps
- [ ] `test/assets/todo_gadget_mobile_css_contract_test.rb` — covers TEST-01
- [ ] `features/02.タスク.feature` (extend) — add `@mobile_portal` scenario for TEST-02

*(Existing test infrastructure (test_helper, env.rb, window_resize.rb, todos.rb, modern_theme.rb) requires no changes)*

## Security Domain

Security enforcement does not apply to this phase — test files only; no authentication flows, input validation, or cryptographic operations are introduced.

## Sources

### Primary (HIGH confidence)
- Codebase: `test/assets/mobile_responsive_contract_test.rb` — CSS contract test pattern (File.read + assert_match with regex)
- Codebase: `test/assets/css_architecture_contract_test.rb` — class naming and require pattern
- Codebase: `features/support/window_resize.rb` — `@mobile_portal` hook, `ensure_mobile_viewport!`, `resize_browser_window`
- Codebase: `features/step_definitions/modern_theme.rb` — `ルートページを開きます。` step definition
- Codebase: `features/step_definitions/todos.rb` — `click_todo_gadget_new_link`, `設定画面で タスクを表示する` step, `追加 をクリック` step
- Codebase: `app/assets/stylesheets/welcome.css.scss` — confirmed `@media (hover: none)` block at lines ~319-325
- Codebase: `features/support/preferences_reset.rb` — confirmed `use_todo` is unchecked by default during sign_in
- Codebase: `app/models/todo_gadget.rb` — confirmed `gadget_id` returns `'todo'`, so CSS selector `#todo` is correct
- Codebase: `config/locales/ja.yml` — confirmed submit button label is `登録` (`todos.form.create`)
- Codebase: `features/03.モダンテーマ.feature` + `features/support/hooks.rb` — `@mobile_portal` tag usage precedent

### Secondary (MEDIUM confidence)
- Selenium WebDriver specification: `isDisplayed()` algorithm excludes CSS transform and overflow:hidden from visibility determination [ASSUMED — not re-verified in this session; consistent with known WebDriver spec]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — test infrastructure is fully established in the codebase
- Architecture: HIGH — all patterns verified against existing files
- Pitfalls: HIGH (Pitfalls 1-3, 5) / MEDIUM (Pitfall 4 — Selenium interactability behavior is assumed)

**Research date:** 2026-06-26
**Valid until:** 2026-07-26 (stable Rails/Cucumber stack; no external dependencies)
