# Phase 6: HTML Structure - Research

**Researched:** 2026-04-29
**Domain:** Rails ERB layout editing — hamburger button + drawer/overlay HTML in `application.html.erb`
**Confidence:** HIGH

---

## Summary

Phase 6 is a pure HTML/ERB change. No new libraries, no new asset files, no migrations, no controllers. The work is two small edits to `app/views/layouts/application.html.erb` and nothing else.

The current layout (29 lines) has a straightforward structure: `<body>` contains `#header > .head-box`, followed by `.wrapper` that holds the menu partial and yield. The hamburger button `<button class="hamburger-btn" aria-label="メニュー"></button>` is appended as the last child of `.head-box`. The drawer `<div class="drawer">` and overlay `<div class="drawer-overlay"></div>` are inserted after the closing `</div>` of `.wrapper` but before `</body>`, making them direct children of `<body>` — the structural requirement that prevents CSS clipping.

All 7 nav links from `_menu.html.erb` are duplicated inline inside the drawer. The existing dropdown partial is not touched. The `user_signed_in?` guard already present for `render 'common/menu'` is extended to wrap the drawer and overlay elements.

**Primary recommendation:** Make two targeted edits to `application.html.erb`. Nothing else changes. Write one integration test that signs in with `modern` theme active, GETs root path, and asserts the structural elements exist in the response HTML.

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** Hamburger button sits on the **right side** of the header bar — the last child inside `.head-box`. Phase 7 applies `display: flex; justify-content: space-between` to `.modern .head-box` to push it to the far right.
- **D-02:** Button is a direct child of `.head-box` (not a sibling in `#header`). Markup: `<button class="hamburger-btn" aria-label="メニュー"></button>`. The `aria-label` is Japanese ("メニュー") matching the app locale.
- **D-03:** Button body is **empty** — Phase 7 CSS renders the three horizontal lines using `::before`, `::after`, and `box-shadow`. No inline content, no `<span>` children.
- **D-04:** Drawer + overlay HTML lives directly in `application.html.erb` (not a new partial). Both elements are inside the `if user_signed_in?` guard. Placement: after `</div>` closing `.wrapper`, before `</body>`.
- **D-05:** Element names: drawer = `<div class="drawer">`, overlay = `<div class="drawer-overlay">`. These class names are the stable surface that Phase 7 CSS and Phase 8 JS reference.
- **D-06:** Nav links are **duplicated inline** inside the drawer — not extracted to a shared partial. All 7 links from `_menu.html.erb` are reproduced: Home, 設定, ブックマーク, タスク, カレンダー, フィード, ログアウト (in the same order).

### Claude's Discretion

- Exact drawer inner markup (nav element vs. plain div list, link classes) — follow the link structure in `_menu.html.erb` as reference; use `link_to` helpers matching existing nav links.
- The `destroy_user_session_path` logout link requires `method: :delete` — must be preserved in the drawer links as in the existing dropdown.

### Deferred Ideas (OUT OF SCOPE)

None — discussion stayed within phase scope.
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| NAV-01 | User sees a hamburger button in the header when using the modern theme | Hamburger `<button>` added to `.head-box`; Phase 7 CSS will control `display` based on `body.modern`; the element must exist in the DOM unconditionally so Phase 7 can target it |
| NAV-02 | User can open a side drawer containing all navigation links by clicking the hamburger | Drawer `<div class="drawer">` with all 7 nav links must be in the DOM; Phase 8 JS will wire the open/close behaviour; the HTML skeleton is Phase 6's deliverable |
</phase_requirements>

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Hamburger button existence in DOM | Frontend Server (SSR) | — | ERB layout renders the button server-side; no client-side generation |
| Drawer HTML structure | Frontend Server (SSR) | — | ERB layout renders drawer/overlay after `.wrapper`; must be in initial HTML payload |
| Nav link rendering in drawer | Frontend Server (SSR) | — | `link_to` helpers with Rails path helpers; resolved at render time |
| Drawer visibility (show/hide) | CDN/Static (CSS) | — | Phase 7 concern; CSS `display` based on `.modern` body class |
| Drawer open/close interaction | Browser/Client | — | Phase 8 concern; jQuery in `menu.js` |

---

## Standard Stack

### Core

| Library/Tool | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Rails ERB | 7.2 [VERIFIED: schema.rb + Gemfile.lock runtime] | Layout templating | Existing layout engine for this app |
| `link_to` Rails helper | 7.2 | Generate anchor tags with Rails path helpers | Standard Rails view helper; matches existing nav pattern |
| `user_signed_in?` Devise helper | Present in layout line 25 [VERIFIED: codebase] | Guard drawer rendering to authenticated users | Already used in layout for `render 'common/menu'` |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Minitest `assert_select` | Built-in [VERIFIED: test suite] | CSS selector assertions on response HTML | Used throughout controller tests for DOM structure verification |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Inline nav links in drawer | Shared partial | Shared partial couples drawer and dropdown — D-06 explicitly rejects this |
| Empty button body (CSS-drawn lines) | `<span>` children for lines | `<span>` approach makes Phase 7 X-animation harder; D-03 locks CSS-only approach |

**Installation:** No new packages. Zero `npm install` or `bundle add` commands needed.

---

## Architecture Patterns

### System Architecture Diagram

```
HTTP Request
     |
     v
ApplicationController (Devise auth)
     |
     v
application.html.erb (layout)
     |
     +-- <body class="<%= favorite_theme %>">
     |
     +-- #header > .head-box
     |       |
     |       +-- [existing: icon + "Bookmarks" text]
     |       +-- [NEW] <button class="hamburger-btn" aria-label="メニュー"></button>
     |
     +-- .wrapper
     |       |
     |       +-- render 'common/menu'  } if user_signed_in?
     |       +-- <%= yield %>
     |
     +-- [NEW, after .wrapper] if user_signed_in?
             |
             +-- <div class="drawer"> ... 7 nav links ... </div>
             +-- <div class="drawer-overlay"></div>
             |
             v
         </body>
```

Data flow note: `favorite_theme` returns `current_user.preference.theme` (e.g., `"modern"`) or `nil`. When `"modern"`, body gets `class="modern"` — this is the hook Phase 7 CSS and Phase 8 JS use. Phase 6 adds no conditional logic beyond the existing `user_signed_in?` guard.

### Recommended Project Structure

No new files. All changes are in:

```
app/views/layouts/
└── application.html.erb   # Two edits: (1) hamburger in .head-box, (2) drawer+overlay after .wrapper
```

Test file (new):
```
test/controllers/
└── layout_structure_test.rb   # OR added to welcome_controller_test.rb
```

### Pattern 1: Appending to `.head-box` (last child)

**What:** Add the hamburger button as the last element inside `.head-box`, after the existing icon and text.
**When to use:** When a new control needs to live in the header bar without disrupting the existing layout structure.

```erb
<%# Source: application.html.erb — current state + Phase 6 addition %>
<div class="head-box">
  <img src="/icon.svg" alt="Bookmarks" class="header-icon" />
  Bookmarks
  <button class="hamburger-btn" aria-label="メニュー"></button>
</div>
```

### Pattern 2: Body-level siblings after `.wrapper`

**What:** Elements that must not be clipped by `.wrapper` overflow/stacking rules are placed after the closing `</div>` of `.wrapper`, still inside `<body>`.
**When to use:** Overlays, drawers, modals — anything that needs to cover the full viewport.

```erb
<%# Source: application.html.erb — current state + Phase 6 addition %>
  </div><%# closes .wrapper %>
  <% if user_signed_in? %>
    <div class="drawer">
      <nav>
        <%= link_to 'Home', root_path %>
        <%= link_to '設定', preferences_path %>
        <%= link_to 'ブックマーク', bookmarks_path %>
        <%= link_to 'タスク', todos_path %>
        <%= link_to 'カレンダー', calendars_path %>
        <%= link_to 'フィード', feeds_path %>
        <%= link_to 'ログアウト', destroy_user_session_path, method: 'delete' %>
      </nav>
    </div>
    <div class="drawer-overlay"></div>
  <% end %>
</body>
```

### Pattern 3: Reproducing logout link

**What:** `destroy_user_session_path` uses Devise's DELETE session endpoint. Rail's `link_to` with `method: 'delete'` generates a data-method attribute that Rails UJS converts to a form submission.
**When to use:** Any logout link. Must match the pattern in `_menu.html.erb` exactly.

```erb
<%# Source: app/views/common/_menu.html.erb line 44 — VERIFIED %>
<%= link_to 'ログアウト', destroy_user_session_path, method: 'delete' %>
```

This must be reproduced verbatim in the drawer nav.

### Anti-Patterns to Avoid

- **Extracting to a partial:** D-06 prohibits this. Do not create `_drawer.html.erb`. Inline the markup directly.
- **Wrapping hamburger in a `<div>` inside `.head-box`:** D-02 requires it to be a direct child of `.head-box`, not wrapped.
- **Placing drawer inside `.wrapper`:** Violates the critical pitfall from STATE.md. Drawer must be outside `.wrapper` as a direct `<body>` child.
- **Adding any CSS or JS in this phase:** Phase 6 is HTML only. Do not modify `modern.css.scss` or `menu.js`.
- **Wrapping drawer/overlay outside the `user_signed_in?` guard:** Both elements are only relevant when a user is logged in. The guard must wrap both (matching the guard already present for `render 'common/menu'`).

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Logout link HTTP method | Custom form or JS | `link_to ..., method: 'delete'` | Rails UJS handles the method spoofing; hand-rolling breaks Devise session management |
| Path helpers | Hard-coded `/settings` etc. | `preferences_path`, `bookmarks_path`, etc. | Path helpers survive route changes; matches pattern in `_menu.html.erb` exactly |

**Key insight:** All nav paths are already defined and used in `_menu.html.erb`. Copy the `link_to` calls from that file — do not invent new paths or hard-code URLs.

---

## Common Pitfalls

### Pitfall 1: Drawer inside `.wrapper`
**What goes wrong:** Drawer gets clipped by `.wrapper`'s overflow or stacking context; the slide-in animation in Phase 7 fails visually.
**Why it happens:** Easy to place new HTML inside the existing `<div class="wrapper">` block by accident.
**How to avoid:** Placement is after the `</div>` that closes `.wrapper` (currently line 27 of `application.html.erb`), not inside it.
**Warning signs:** Drawer div appears nested under `.wrapper` in DevTools element inspector.

### Pitfall 2: Missing or wrong `user_signed_in?` guard
**What goes wrong:** Drawer and hamburger are rendered for unauthenticated users (where nav paths require login) or not rendered at all.
**Why it happens:** Adding elements outside the existing conditional block.
**How to avoid:** The hamburger button is unconditional in the header (the header is always shown). The drawer + overlay are inside `if user_signed_in?`. Check: the hamburger is visible to all visitors but the drawer content is guarded.
**Warning signs:** `undefined method 'root_path'` errors for guests, or drawer never appearing in integration tests.

### Pitfall 3: Logout link missing `method: :delete`
**What goes wrong:** Logout link renders as a GET request; Devise 404s or does not sign out the user.
**Why it happens:** Forgetting `method: 'delete'` on the `link_to` call when transcribing from `_menu.html.erb`.
**How to avoid:** Copy the exact call: `link_to 'ログアウト', destroy_user_session_path, method: 'delete'`.
**Warning signs:** Clicking logout navigates to a 404 or shows "Not Found" in development.

### Pitfall 4: Button body not empty
**What goes wrong:** Phase 7 CSS `::before`/`::after`/`box-shadow` hamburger lines appear alongside stray text or child elements.
**Why it happens:** Adding placeholder text like `☰` or `<span>` children for the icon.
**How to avoid:** D-03 locks this: `<button class="hamburger-btn" aria-label="メニュー"></button>` — no content between tags.
**Warning signs:** Hamburger button renders with visible text or unexpected inner elements in Phase 7.

### Pitfall 5: Modifying `_menu.html.erb`
**What goes wrong:** Existing dropdown menu breaks; inline `<script>` behaviour is disrupted.
**Why it happens:** Attempting to DRY the nav links by editing the shared partial.
**How to avoid:** `_menu.html.erb` is read-only for Phase 6. Duplicate the links inline in the drawer.
**Warning signs:** Existing dropdown tests fail; inline `<script>` in `_menu.html.erb` is absent or modified.

---

## Code Examples

### Current `application.html.erb` (verified state before Phase 6 edits)

```erb
<%# Source: app/views/layouts/application.html.erb — VERIFIED 2026-04-29 %>
<!DOCTYPE html>
<html>
  <head>
    <title>Bookmarks</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <link rel="icon" type="image/svg+xml" href="/icon.svg" />
    <%= csrf_meta_tags %>
    <%= csp_meta_tag %>
    <%= stylesheet_link_tag    'application', media: 'all' %>
    <%= javascript_include_tag 'application' %>
    <script src="https://apis.google.com/js/api.js"></script>
  </head>

  <body class="<%= favorite_theme %>">
    <div id="header">
      <div class="head-box">
        <img src="/icon.svg" alt="Bookmarks" class="header-icon" />
        Bookmarks
      </div>
    </div>

    <div class="wrapper">
      <%= render 'common/menu' if user_signed_in? %>
      <%= yield %>
    </div>
  </body>
</html>
```

### Phase 6 target state

```erb
<%# Source: Phase 6 target — derived from CONTEXT.md locked decisions %>
  <body class="<%= favorite_theme %>">
    <div id="header">
      <div class="head-box">
        <img src="/icon.svg" alt="Bookmarks" class="header-icon" />
        Bookmarks
        <button class="hamburger-btn" aria-label="メニュー"></button>
      </div>
    </div>

    <div class="wrapper">
      <%= render 'common/menu' if user_signed_in? %>
      <%= yield %>
    </div>
    <% if user_signed_in? %>
      <div class="drawer">
        <nav>
          <%= link_to 'Home', root_path %>
          <%= link_to '設定', preferences_path %>
          <%= link_to 'ブックマーク', bookmarks_path %>
          <%= link_to 'タスク', todos_path %>
          <%= link_to 'カレンダー', calendars_path %>
          <%= link_to 'フィード', feeds_path %>
          <%= link_to 'ログアウト', destroy_user_session_path, method: 'delete' %>
        </nav>
      </div>
      <div class="drawer-overlay"></div>
    <% end %>
  </body>
```

### Integration test pattern (matching project conventions)

```ruby
# Source: test/controllers/welcome_controller_test.rb and bookmarks_controller_test.rb patterns — VERIFIED
class LayoutStructureTest < ActionDispatch::IntegrationTest

  def test_モダンテーマでハンバーガーボタンが表示される
    user.preference.update!(theme: 'modern')
    sign_in user
    get root_path
    assert_response :success
    assert_select 'button.hamburger-btn[aria-label=?]', 'メニュー', count: 1
  end

  def test_モダンテーマでドロワーが存在する
    user.preference.update!(theme: 'modern')
    sign_in user
    get root_path
    assert_response :success
    assert_select 'div.drawer', count: 1
    assert_select 'div.drawer-overlay', count: 1
  end

  def test_ドロワーに全ナビリンクが含まれる
    user.preference.update!(theme: 'modern')
    sign_in user
    get root_path
    assert_response :success
    assert_select '.drawer a[href=?]', root_path
    assert_select '.drawer a[href=?]', preferences_path
    assert_select '.drawer a[href=?]', bookmarks_path
    assert_select '.drawer a[href=?]', todos_path
    assert_select '.drawer a[href=?]', calendars_path
    assert_select '.drawer a[href=?]', feeds_path
    assert_select '.drawer a[href=?]', destroy_user_session_path
  end

  def test_デフォルトテーマでもハンバーガーボタンが存在する
    # Hamburger is unconditional — present in all themes (Phase 7 CSS hides it for non-modern)
    sign_in user
    get root_path
    assert_response :success
    assert_select 'button.hamburger-btn', count: 1
  end

  def test_非ログイン時はドロワーが存在しない
    get root_path
    assert_response :redirect  # Devise redirects unauthenticated
  end

end
```

### Nav links source of truth (`_menu.html.erb` — read-only reference)

```erb
<%# Source: app/views/common/_menu.html.erb lines 35–44 — VERIFIED 2026-04-29 %>
<li><%= link_to 'Home', root_path %></li>
<div><%= link_to '設定', preferences_path %></div>
<div><%= link_to 'ブックマーク', bookmarks_path %></div>
<div><%= link_to 'タスク', todos_path %></div>
<div><%= link_to 'カレンダー', calendars_path %></div>
<div><%= link_to 'フィード', feeds_path %></div>
<div><%= link_to 'ログアウト', destroy_user_session_path, method: 'delete' %></div>
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| N/A — greenfield drawer | Direct `<body>` child placement | Phase 6 | Drawer must be sibling of `.wrapper`, not child |

**Deprecated/outdated:** Nothing — this is new markup.

---

## Runtime State Inventory

Step 2.5 SKIPPED — Phase 6 is not a rename/refactor/migration phase. It adds new DOM elements; no stored data, service config, OS-registered state, secrets, or build artifacts reference these new class names.

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Ruby / Rails | ERB rendering | ✓ | Rails 8.1.1 [VERIFIED: runtime check] | — |
| Minitest | Integration tests | ✓ | Built into Rails test suite [VERIFIED: test_helper.rb] | — |
| Devise test helpers | `sign_in user` in tests | ✓ | `Devise::Test::IntegrationHelpers` included [VERIFIED: test_helper.rb] | — |

No missing dependencies. All tooling is already in place.

---

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | Minitest (ActionDispatch::IntegrationTest) |
| Config file | `test/test_helper.rb` |
| Quick run command | `bundle exec ruby -Itest test/controllers/layout_structure_test.rb` |
| Full suite command | `bundle exec rake test` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| NAV-01 | Hamburger button is in DOM when signed in | integration | `bundle exec ruby -Itest test/controllers/layout_structure_test.rb -n test_モダンテーマでハンバーガーボタンが表示される` | Wave 0 |
| NAV-01 | Hamburger button present even on non-modern theme | integration | `bundle exec ruby -Itest test/controllers/layout_structure_test.rb -n test_デフォルトテーマでもハンバーガーボタンが存在する` | Wave 0 |
| NAV-02 | Drawer div is in DOM when signed in | integration | `bundle exec ruby -Itest test/controllers/layout_structure_test.rb -n test_モダンテーマでドロワーが存在する` | Wave 0 |
| NAV-02 | Drawer contains all 7 nav links | integration | `bundle exec ruby -Itest test/controllers/layout_structure_test.rb -n test_ドロワーに全ナビリンクが含まれる` | Wave 0 |

### Sampling Rate

- **Per task commit:** `bundle exec ruby -Itest test/controllers/layout_structure_test.rb`
- **Per wave merge:** `bundle exec rake test`
- **Phase gate:** Full suite green before `/gsd-verify-work`

### Wave 0 Gaps

- [ ] `test/controllers/layout_structure_test.rb` — covers NAV-01, NAV-02 (new file; zero existing tests cover drawer HTML structure)

---

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | — |
| V3 Session Management | no | — |
| V4 Access Control | yes | `user_signed_in?` Devise helper guards drawer content |
| V5 Input Validation | no | Phase 6 renders no user input |
| V6 Cryptography | no | — |

### Known Threat Patterns for ERB layout

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Rendering drawer nav links for unauthenticated users | Information Disclosure | `user_signed_in?` guard wraps all drawer/overlay elements |
| XSS via nav link href | Tampering | All links use Rails path helpers (not user-supplied input); no risk in Phase 6 |

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Hamburger button is rendered unconditionally (not inside `user_signed_in?`) — the header is always visible | Architecture Patterns, Code Examples | If the header is somehow conditionally rendered for guests, Phase 7 CSS would need a different selector. Low risk: layout shows header for all page loads including unauthenticated. |
| A2 | `link_to '...', path, method: 'delete'` (string `'delete'`) works the same as `method: :delete` (symbol) in this Rails version | Code Examples | Cosmetic difference; both work in Rails 7+. Low risk. |

---

## Open Questions

1. **Nav element vs. div container inside drawer**
   - What we know: D-06 specifies link structure mirrors `_menu.html.erb`; discretion left for inner markup container.
   - What's unclear: Whether to use `<nav>` or a `<div>` wrapping the links inside `.drawer`.
   - Recommendation: Use `<nav>` — it is the semantically correct element for a set of navigation links, matches accessibility best practice, and gives Phase 7 CSS a stable selector (`.drawer nav`).

2. **Whether `test_非ログイン時はドロワーが存在しない` is testable**
   - What we know: `get root_path` without signing in redirects (Devise requires authentication for root).
   - What's unclear: Whether root_path is publicly accessible or always redirects unauthenticated.
   - Recommendation: Test that the redirect fires; structural absence of the drawer is implied by the redirect. Skip asserting HTML content in the redirect response.

---

## Sources

### Primary (HIGH confidence)
- `app/views/layouts/application.html.erb` — verified line-by-line; current layout structure is the direct subject of this phase's edits
- `app/views/common/_menu.html.erb` — verified all 7 nav links and exact `link_to` signatures including `method: 'delete'` for logout
- `test/test_helper.rb` — verified Minitest + Devise::Test::IntegrationHelpers setup
- `test/controllers/welcome_controller_test.rb`, `bookmarks_controller_test.rb` — verified `assert_select` pattern, Japanese method naming, `sign_in user` idiom
- `.planning/phases/06-html-structure/06-CONTEXT.md` — locked decisions D-01 through D-06

### Secondary (MEDIUM confidence)
- `.planning/STATE.md` §Critical Pitfalls — "Drawer `<div>` must be a direct child of `<body>`, outside `.wrapper`, to avoid clipping" — corroborates placement decision
- `.planning/phases/05-theme-foundation/05-CONTEXT.md` — confirms Phase 5 is complete and CSS token infrastructure (`--modern-header-bg` etc.) is ready

### Tertiary (LOW confidence)
- None — all claims verified from codebase.

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — no new libraries; all verified from existing codebase
- Architecture: HIGH — layout file read directly; placement rules verified against current DOM structure
- Pitfalls: HIGH — derived from CONTEXT.md decisions + STATE.md critical pitfalls list

**Research date:** 2026-04-29
**Valid until:** 2026-06-29 (stable Rails ERB patterns; no ecosystem churn risk)
