# Phase 89: Static Policy Pages - Research

**Researched:** 2026-05-19
**Domain:** Rails static pages, i18n YAML, skip_before_action auth bypass
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- New `PagesController < ApplicationController` with `skip_before_action :authenticate_user!`
- Simple `get 'privacy', to: 'pages#privacy'` and `get 'terms', to: 'pages#terms'` routes inside the `unless ARGV.first =~ /^dad:setup(:.+)?/` block in `config/routes.rb`
- Use existing `application.html.erb` layout — shows header consistently, same as landing page
- `Localization` concern inherited from `ApplicationController` automatically — locale param works out of the box
- Policy text stored in locale YAML files (`ja.yml` / `en.yml`) under `pages.privacy.*` and `pages.terms.*` — matches existing i18n pattern
- Multiple keys per section (e.g., `pages.privacy.sections.data_collected`, `pages.privacy.sections.x_login`) — each section rendered as a prose block by ERB
- Privacy policy sections: data collected, purpose of X login, email address handling, data retention, contact
- Terms of service sections: acceptable use, service availability, account termination
- Locale switcher links at top of each page using `privacy_path(locale: 'ja')` / `privacy_path(locale: 'en')` — same pattern as landing page lang switcher
- "← Back to home" link pointing to `root_path`
- Minitest integration tests in `test/controllers/privacy_controller_test.rb` and `test/controllers/terms_controller_test.rb`
- New SCSS file: `app/assets/stylesheets/pages.css.scss` — minimal, scoped to `.policy-*` classes only
- Reuse `.landing-page`, `.landing-lang-switcher`, `.landing-lang-link`, `.landing-lang-link--active` without modification
- New classes: `.policy-content`, `.policy-section-heading`, `.policy-back-link` — exact values specified in UI-SPEC

### Claude's Discretion

- (none specified — all implementation decisions are locked)

### Deferred Ideas (OUT OF SCOPE)

- Footer links to `/privacy` and `/terms`
- Landing page links to policy pages
- Cookie consent banner
- GDPR data export/deletion
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| PRIV-01 | User can view a privacy policy page at `/privacy` without authentication | `skip_before_action :authenticate_user!` in PagesController; route `get 'privacy', to: 'pages#privacy'` |
| PRIV-02 | Privacy policy content available in Japanese and English | Locale YAML under `pages.privacy.sections.*` with `heading` and `body` sub-keys; `Localization` concern resolves locale from param or Accept-Language |
| PRIV-03 | Privacy policy covers data collected, X login purpose, email handling, data retention | Five YAML sections: `data_collected`, `x_login`, `email_handling`, `data_retention`, `contact` |
| TOS-01 | User can view a terms of service page at `/terms` without authentication | Same PagesController pattern; route `get 'terms', to: 'pages#terms'` |
| TOS-02 | Terms of service content available in Japanese and English | Locale YAML under `pages.terms.sections.*`; same i18n infrastructure |
| TOS-03 | Terms of service covers acceptable use, service availability, account termination | Three YAML sections: `acceptable_use`, `availability`, `termination` |
</phase_requirements>

---

## Summary

Phase 89 delivers two public, bilingual static pages (`/privacy`, `/terms`) in a Rails 7.2 app. The implementation is entirely greenfield at the controller/view level but relies heavily on existing infrastructure: the `Localization` concern for locale resolution, the `application.html.erb` layout, and the landing page's CSS classes for visual consistency. No database changes, no JavaScript, no third-party packages.

The key technical constraint is that `ApplicationController` has a global `before_action :authenticate_user!`. The established pattern for bypassing this is `skip_before_action :authenticate_user!` — used in `WelcomeController` (for the `index` action) and in `Users::TwoFactorAuthenticationController`. `PagesController` follows the same pattern, skipping for all actions.

The `Localization` concern (in `app/controllers/concerns/localization.rb`) resolves locale via `params[:locale]` stored in `session[:guest_locale]`, then Accept-Language header, then default. This is already fully compatible with unauthenticated visitors — `guest_session_locale` explicitly handles the unauthenticated case. Locale switcher links using `privacy_path(locale: 'ja')` will write to `session[:guest_locale]` automatically.

The Sprockets manifest (`application.css`) uses `require_tree .` which means a new `pages.css.scss` file dropped into `app/assets/stylesheets/` will be included automatically with no manifest changes needed.

**Primary recommendation:** Create `PagesController`, two views under `app/views/pages/`, YAML keys under `pages:` in both locale files, a minimal `pages.css.scss`, two routes, and two Minitest test files. No tooling changes, no new gems, no asset manifest edits.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Public route access (no auth) | API / Backend (Rails controller) | — | Auth bypass via `skip_before_action` lives in the controller tier |
| Locale resolution | API / Backend (Localization concern) | — | `around_action :set_locale` wraps the request; locale param stored in guest session |
| Content delivery | Frontend Server (ERB views) | — | Static YAML-backed content rendered server-side |
| Styling | CDN / Static (Sprockets-compiled CSS) | — | `pages.css.scss` compiled into `application.css` via `require_tree .` |
| Locale content | CDN / Static (YAML) | — | `config/locales/*.yml` — read at boot, served inline in rendered HTML |

---

## Standard Stack

### Core

No new packages. All capabilities delivered by existing gems.

| Component | Version | Purpose | Why Standard |
|-----------|---------|---------|--------------|
| Rails i18n (`t()`) | 7.2 (bundled) | Translate view strings via locale YAML | Existing pattern throughout the app |
| Sprockets | bundled | CSS compilation | `require_tree .` auto-includes `pages.css.scss` |
| ActionDispatch::IntegrationTest | bundled | Controller tests | Established test pattern for all controllers |

[VERIFIED: codebase grep] — no new gem installation required for this phase.

### Supporting

| Component | Version | Purpose | When to Use |
|-----------|---------|---------|-------------|
| `Localization` concern | project-local | Locale resolution for guests and users | Already included via ApplicationController — no additional wiring |
| `.landing-*` CSS classes | project-local | Lang switcher, page wrapper | Reuse without modification |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| YAML-backed content | Hardcoded strings in views | Violates project i18n convention; all UI strings must go through `t()` |
| YAML-backed content | Database-backed CMS | Massively over-engineered for static policy text on a personal app |
| `application.html.erb` layout | Separate policy layout | No reason for separate layout; header consistency is valuable for X reviewer |

**Installation:** None. No packages to install.

---

## Package Legitimacy Audit

No external packages are being installed in this phase. This section is not applicable.

---

## Architecture Patterns

### System Architecture Diagram

```
Unauthenticated HTTP request
         │
         ▼
  config/routes.rb
  get 'privacy' → pages#privacy
  get 'terms'   → pages#terms
         │
         ▼
  PagesController
  skip_before_action :authenticate_user!
  (all other ApplicationController callbacks inherited:
   Localization concern, render_font_size_migration_notice)
         │
         ├─ around_action :set_locale  (Localization concern)
         │    ├─ params[:locale] → session[:guest_locale]
         │    └─ Accept-Language header fallback
         │
         ▼
  app/views/pages/privacy.html.erb
  app/views/pages/terms.html.erb
         │
         ├─ t('pages.privacy.title') / t('pages.terms.title')
         ├─ t('pages.privacy.sections.*.heading')
         ├─ t('pages.privacy.sections.*.body')
         └─ lang switcher: privacy_path(locale: 'ja/en')
                           terms_path(locale: 'ja/en')
         │
         ▼
  application.html.erb layout
  (header, wrapper, yield, drawer if signed in)
         │
         ▼
  Browser renders HTML
  Sprockets-compiled application.css
  (includes pages.css.scss via require_tree .)
```

### Recommended Project Structure

```
app/
├── controllers/
│   └── pages_controller.rb          # NEW: PagesController
├── views/
│   └── pages/
│       ├── privacy.html.erb         # NEW: privacy policy view
│       └── terms.html.erb           # NEW: terms of service view
└── assets/
    └── stylesheets/
        └── pages.css.scss           # NEW: .policy-* classes only

config/
├── locales/
│   ├── ja.yml                       # MODIFIED: add pages: namespace
│   └── en.yml                       # MODIFIED: add pages: namespace
└── routes.rb                        # MODIFIED: add 2 get routes

test/
└── controllers/
    ├── privacy_controller_test.rb   # NEW
    └── terms_controller_test.rb     # NEW
```

### Pattern 1: skip_before_action for Public Actions

**What:** Override the global `authenticate_user!` filter for specific actions in a controller.
**When to use:** Any controller action that must be accessible to unauthenticated visitors.

**Example (from WelcomeController — VERIFIED: codebase):**
```ruby
# app/controllers/welcome_controller.rb
class WelcomeController < ApplicationController
  skip_before_action :authenticate_user!, only: :index
  # ...
end
```

**PagesController follows the same pattern but skips for all actions:**
```ruby
# app/controllers/pages_controller.rb
class PagesController < ApplicationController
  skip_before_action :authenticate_user!

  def privacy
  end

  def terms
  end
end
```

No `only:` qualifier needed since both actions are public.

### Pattern 2: i18n Locale YAML Namespace

**What:** YAML key hierarchy under a controller/feature namespace with `title`, `back_home`, and nested `sections` keys.
**When to use:** Every new feature's string content.

**Example (modeled on existing landing namespace — VERIFIED: codebase):**
```yaml
# config/locales/ja.yml
ja:
  pages:
    privacy:
      title: プライバシーポリシー
      back_home: "← ホームに戻る"
      sections:
        data_collected:
          heading: 収集する情報
          body: "..."
        x_login:
          heading: X（旧Twitter）ログインの目的
          body: "..."
        email_handling:
          heading: メールアドレスの取り扱い
          body: "..."
        data_retention:
          heading: データ保持
          body: "..."
        contact:
          heading: お問い合わせ
          body: "..."
    terms:
      title: 利用規約
      back_home: "← ホームに戻る"
      sections:
        acceptable_use:
          heading: 利用上のルール
          body: "..."
        availability:
          heading: サービスの提供
          body: "..."
        termination:
          heading: アカウントの終了
          body: "..."
```

### Pattern 3: Locale Switcher Adapter for Non-Root Paths

**What:** Reuse `.landing-lang-switcher` and `.landing-lang-link` CSS classes but point links to the page's own named route.
**When to use:** Any public page that needs locale switching.

**Example (adapted from `_landing.html.erb` — VERIFIED: codebase):**
```erb
<%# In app/views/pages/privacy.html.erb %>
<main class="landing-page">
  <div class="landing-lang-switcher">
    <%= link_to "日本語", privacy_path(locale: 'ja'),
          class: "landing-lang-link #{'landing-lang-link--active' if I18n.locale == :ja}",
          aria: { current: I18n.locale == :ja ? 'true' : nil } %>
    <%= link_to "English", privacy_path(locale: 'en'),
          class: "landing-lang-link #{'landing-lang-link--active' if I18n.locale == :en}",
          aria: { current: I18n.locale == :en ? 'true' : nil } %>
  </div>
  ...
</main>
```

Note: `aria-current="true"` on the active locale link is required by the UI-SPEC accessibility contract.

### Pattern 4: render_font_size_migration_notice on Unauthenticated Requests

**What:** `ApplicationController` has a `before_action :render_font_size_migration_notice` that calls `user_signed_in?` first. It is already safe for unauthenticated requests — it returns early if `!user_signed_in?`. No separate skip is needed.

[VERIFIED: codebase — `def render_font_size_migration_notice; return unless user_signed_in?; ...`]

### Anti-Patterns to Avoid

- **Skipping with `only:`:** `skip_before_action :authenticate_user!, only: [:privacy, :terms]` works but is unnecessarily verbose when the entire controller is public. Skip without `only:` is the correct form here.
- **Hardcoded strings in views:** All visible text must go through `t()`. The UI-SPEC copywriting contract lists every string — each must have a YAML key.
- **Using `bundle exec cucumber` directly:** Project CLAUDE.md requires `bundle exec rake dad:test` for E2E tests. Do not use `bundle exec cucumber` directly.
- **Leaving precompiled assets:** After any `assets:precompile`, run `rails assets:clobber`. (Project memory rule.)

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Locale resolution | Custom `params[:locale]` → session logic | `Localization` concern (`include`d in ApplicationController) | Already handles guest_session_locale, Accept-Language, preference — fully tested |
| SCSS compilation | Explicit manifest edits | `require_tree .` in `application.css` | New `.css.scss` files in the stylesheets directory are auto-included |
| Content internationalization | Locale-switching if/else in views | `t('key')` backed by YAML | Existing pattern; no conditional logic in views needed |

**Key insight:** The entire locale resolution system already handles unauthenticated visitors. `guest_session_locale` stores the selected locale in `session[:guest_locale]` for guests and reads it on subsequent requests — the locale switcher links work for free.

---

## Runtime State Inventory

Step 2.5: SKIPPED — This is a greenfield phase (new controller, new views, new YAML keys, new CSS). No rename, refactor, or migration involved. No runtime state to inventory.

---

## Environment Availability

Step 2.6: SKIPPED — This phase has no external dependencies beyond the project's own code (no CLI tools, no external services, no new runtimes or databases).

---

## Common Pitfalls

### Pitfall 1: Missing `privacy_path` / `terms_path` named route helpers

**What goes wrong:** After adding `get 'privacy', to: 'pages#privacy'`, the named helper is `privacy_path` (not `pages_privacy_path`). If the route is accidentally added without the `as:` default or if the route block is mis-placed, the helper may not exist.
**Why it happens:** Rails auto-generates the named helper from the path string — `get 'privacy'` produces `privacy_path`. But if a developer wraps these in a `namespace` or `scope`, the naming changes.
**How to avoid:** Add both routes directly inside the `unless ARGV.first =~ /^dad:setup/` block at the top level (no namespace, no scope). Verify with `rails routes | grep privacy`.
**Warning signs:** `undefined method 'privacy_path'` in view or test.

### Pitfall 2: Locale switcher writes to guest session but is silently ignored for authenticated users

**What goes wrong:** An authenticated user visits `/privacy?locale=en`. The `Localization` concern checks `saved_locale` first (their preference), which overrides the `?locale=` param for authenticated users.
**Why it happens:** `resolved_locale` priority: `saved_locale` (user preference) > `guest_session_locale` (param) > Accept-Language. Authenticated users always use their preference locale.
**How to avoid:** This is correct behavior — authenticated users keep their preference locale. Tests should verify behavior for the unauthenticated case only. Do not add special handling for the authenticated case.
**Warning signs:** Test failure where authenticated user locale does not change on `?locale=en` — expected; do not fix.

### Pitfall 3: `render_font_size_migration_notice` called on unauthenticated PagesController requests

**What goes wrong:** Developer incorrectly assumes every `before_action` in ApplicationController needs skipping for unauthenticated pages.
**Why it happens:** `render_font_size_migration_notice` is a `before_action` on `ApplicationController`.
**How to avoid:** Read the method — it has `return unless user_signed_in?` as its first line. It is already safe. Only `authenticate_user!` needs skipping.
**Warning signs:** If you skip `render_font_size_migration_notice` unnecessarily, it will still work — but it signals a misunderstanding of the code.

### Pitfall 4: YAML indentation errors break all locale keys

**What goes wrong:** A mis-indented key in `ja.yml` or `en.yml` raises `Psych::SyntaxError` at boot and crashes the app.
**Why it happens:** YAML is whitespace-sensitive. The existing files use 2-space indentation consistently.
**How to avoid:** Follow exact 2-space indentation. Keep body text on a single line with `"..."` quoting or use YAML block scalar (`|`) for multi-line text. Validate by running `ruby -e "require 'yaml'; YAML.load_file('config/locales/ja.yml')"` after editing.
**Warning signs:** Rails boot error mentioning `Psych` or `YAML` with a line number.

### Pitfall 5: `pages.css.scss` not included in compiled output

**What goes wrong:** The new CSS file exists but styles are not applied in the browser.
**Why it happens:** Sprockets `require_tree .` normally auto-includes all files in the directory. However, if the file name starts with `_` (partial), it is not included as a standalone file.
**How to avoid:** Name the file `pages.css.scss` (not `_pages.css.scss`). Verify by checking the compiled `public/assets/application-*.css` after a dev-mode asset compile.
**Warning signs:** Page loads without `.policy-content` background styling.

---

## Code Examples

### PagesController

```ruby
# app/controllers/pages_controller.rb
class PagesController < ApplicationController
  skip_before_action :authenticate_user!

  def privacy
  end

  def terms
  end
end
```

[ASSUMED based on WelcomeController pattern — verified via codebase that `skip_before_action :authenticate_user!` is the established pattern]

### Routes addition

```ruby
# config/routes.rb (inside unless ARGV.first =~ /^dad:setup/ block, before the resources block)
get 'privacy', to: 'pages#privacy'
get 'terms',   to: 'pages#terms'
```

[VERIFIED: codebase — existing routes.rb structure confirmed]

### View template structure (privacy.html.erb)

```erb
<%# app/views/pages/privacy.html.erb %>
<main class="landing-page">
  <div class="landing-lang-switcher">
    <%= link_to "日本語", privacy_path(locale: 'ja'),
          class: "landing-lang-link #{'landing-lang-link--active' if I18n.locale == :ja}",
          aria: { current: (I18n.locale == :ja ? 'true' : nil) } %>
    <%= link_to "English", privacy_path(locale: 'en'),
          class: "landing-lang-link #{'landing-lang-link--active' if I18n.locale == :en}",
          aria: { current: (I18n.locale == :en ? 'true' : nil) } %>
  </div>

  <div class="policy-back-link">
    <%= link_to t('pages.privacy.back_home'), root_path %>
  </div>

  <article class="policy-content">
    <h1><%= t('pages.privacy.title') %></h1>

    <% %w[data_collected x_login email_handling data_retention contact].each do |section| %>
      <section>
        <h2 class="policy-section-heading"><%= t("pages.privacy.sections.#{section}.heading") %></h2>
        <p><%= t("pages.privacy.sections.#{section}.body") %></p>
      </section>
    <% end %>
  </article>
</main>
```

Note: The loop-based approach (`each do |section|`) works but requires the YAML keys to be consistently named. An alternative is to render each section explicitly — either approach is valid. Explicit rendering is clearer but more verbose.

### Test pattern (modeled on WelcomeController::RootPathTest)

```ruby
# test/controllers/privacy_controller_test.rb
require 'test_helper'

class PrivacyControllerTest < ActionDispatch::IntegrationTest
  def test_未認証でprivacyは200を返す
    get privacy_path
    assert_response :success
  end

  def test_privacyはランディングページ構造を使う
    get privacy_path
    assert_select 'main.landing-page', count: 1
  end

  def test_privacyは日本語ロケールで日本語タイトルを表示する
    get privacy_path
    assert_select 'h1', text: 'プライバシーポリシー'
  end

  def test_privacyは英語ロケールで英語タイトルを表示する
    get privacy_path, params: { locale: 'en' }
    assert_select 'h1', text: 'Privacy Policy'
  end

  def test_privacyは認証リダイレクトしない
    get privacy_path
    assert_response :success
    refute_equal new_user_session_path, response.location
  end
end
```

[ASSUMED pattern modeled on `WelcomeController::RootPathTest` — codebase verified]

### SCSS new file

```scss
// app/assets/stylesheets/pages.css.scss
.policy-content {
  background: #f7f9fc;
  border: 1px solid #d8e1ef;
  border-radius: 12px;
  padding: 32px 24px;
  margin-top: 16px;

  h1 {
    margin: 0 0 24px;
    font-size: 1.6rem;
    font-weight: 600;
    line-height: 1.2;
  }
}

.policy-section-heading {
  font-size: 1.1rem;
  font-weight: 600;
  line-height: 1.3;
  margin: 24px 0 8px;
  color: #333;
}

.policy-back-link {
  margin-bottom: 8px;

  a, a:visited {
    color: #4f6b95;
    font-size: 13px;
    font-weight: 600;
    text-decoration: none;

    &:hover {
      color: #2f6feb;
      text-decoration: underline;
    }
  }
}

@media (max-width: 767px) {
  .policy-content {
    padding: 16px;
  }
}
```

[VERIFIED: exact values from 89-UI-SPEC.md]

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Devise: `before_filter` | `before_action` | Rails 4 | Syntax only |
| Manual locale param handling | `Localization` concern with guest session | Existing in project | Already done — no new work |

**Deprecated/outdated:**
- None relevant to this phase.

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | PagesController action names are `privacy` and `terms` (no index action, no resource convention) | Architecture Patterns | Low — this exactly matches the route definitions in CONTEXT.md |
| A2 | Test file placement under `test/controllers/` (flat, not in subdirectory) matching most existing tests | Code Examples | Low — existing tests use both flat and subdirectory organization; either works |
| A3 | Locale YAML body text uses single-key `body:` per section (not multiple paragraph keys) | Architecture Patterns | Medium — if body text is long, multi-paragraph YAML (`\n\n`) may be needed; `simple_format` helper or `html_safe` may be required |

**Note on A3:** The UI-SPEC states "full substantive prose" per section. If body text contains paragraph breaks, the ERB template needs `<%= simple_format(t(...)) %>` instead of `<p><%= t(...) %></p>`. The planner should decide whether body text is single-paragraph per section (use `<p>`) or multi-paragraph (use `simple_format`). Given that X Developer Portal will review the content, multi-paragraph body text is likely.

---

## Open Questions (RESOLVED)

1. **Single-paragraph vs. multi-paragraph section body text**
   - What we know: Each YAML section has a `body` key
   - What's unclear: Whether body text spans multiple paragraphs
   - Recommendation: Use `simple_format(t("pages.privacy.sections.#{section}.body"))` to handle both single-line and multi-paragraph content safely; `simple_format` wraps in `<p>` tags and converts `\n\n` to paragraph breaks

2. **`render_font_size_migration_notice` side effect**
   - What we know: The method begins with `return unless user_signed_in?`
   - What's unclear: Nothing — it is safe for unauthenticated requests
   - Recommendation: No action needed; confirm during verification

---

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | Minitest / ActionDispatch::IntegrationTest |
| Config file | `test/test_helper.rb` |
| Quick run command | `bin/rails test test/controllers/privacy_controller_test.rb test/controllers/terms_controller_test.rb` |
| Full suite command | `bin/rails test` |

### Phase Requirements to Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| PRIV-01 | GET /privacy without auth returns 200 | integration | `bin/rails test test/controllers/privacy_controller_test.rb` | ❌ Wave 0 |
| PRIV-02 | Privacy page renders Japanese content at `:ja`, English at `:en` | integration | `bin/rails test test/controllers/privacy_controller_test.rb` | ❌ Wave 0 |
| PRIV-03 | Privacy page body contains section headings for data, X login, email, retention | integration | `bin/rails test test/controllers/privacy_controller_test.rb` | ❌ Wave 0 |
| TOS-01 | GET /terms without auth returns 200 | integration | `bin/rails test test/controllers/terms_controller_test.rb` | ❌ Wave 0 |
| TOS-02 | Terms page renders Japanese content at `:ja`, English at `:en` | integration | `bin/rails test test/controllers/terms_controller_test.rb` | ❌ Wave 0 |
| TOS-03 | Terms page body contains section headings for use, availability, termination | integration | `bin/rails test test/controllers/terms_controller_test.rb` | ❌ Wave 0 |

### Sampling Rate

- **Per task commit:** `bin/rails test test/controllers/privacy_controller_test.rb test/controllers/terms_controller_test.rb`
- **Per wave merge:** `bin/rails test`
- **Phase gate:** `yarn run lint && bin/rails test && bundle exec rake dad:test`

### Wave 0 Gaps

- [ ] `test/controllers/privacy_controller_test.rb` — covers PRIV-01, PRIV-02, PRIV-03
- [ ] `test/controllers/terms_controller_test.rb` — covers TOS-01, TOS-02, TOS-03

*(No test framework install needed — Minitest already configured)*

---

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes (bypass) | `skip_before_action :authenticate_user!` — explicit bypass, not accidental |
| V3 Session Management | no | Read-only pages; locale param writes to guest_session only (no sensitive data) |
| V4 Access Control | no | Pages are intentionally public; no user data exposed |
| V5 Input Validation | no | No user input accepted; locale param validated against `Preference::SUPPORTED_LOCALES` allowlist in `Localization` concern |
| V6 Cryptography | no | No cryptographic operations |

### Known Threat Patterns

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Open redirect via `locale` param | Tampering | `Localization` concern validates param against `Preference::SUPPORTED_LOCALES` allowlist — non-matching values silently ignored |
| XSS via YAML body text | Tampering | `t()` HTML-escapes by default in Rails; if `html_safe` or `raw` is used for multi-paragraph formatting, `simple_format` auto-escapes; never use `raw(t(...))` |

---

## Project Constraints (from CLAUDE.md)

| Directive | Category | Impact on Phase |
|-----------|----------|-----------------|
| Three test suites must pass: `yarn run lint`, `bin/rails test`, `bundle exec rake dad:test` | Testing | Phase gate requires all three green |
| Cucumber via `bundle exec rake dad:test` only (not `bundle exec cucumber`) | Testing | If Cucumber scenarios are added for policy pages, use the rake task |
| Run `rails assets:clobber` after any `assets:precompile` | Assets | Applies if manual precompile is run during development |
| Never push to remote | Git | All `git push` operations done manually by user |

---

## Sources

### Primary (HIGH confidence)

- Codebase: `app/controllers/welcome_controller.rb` — `skip_before_action` pattern verified
- Codebase: `app/controllers/concerns/localization.rb` — locale resolution and guest session logic verified
- Codebase: `app/assets/stylesheets/landing.css.scss` — exact CSS values for reused classes verified
- Codebase: `app/views/welcome/_landing.html.erb` — lang switcher pattern verified
- Codebase: `config/routes.rb` — route structure and `unless ARGV.first` block verified
- Codebase: `config/locales/ja.yml`, `en.yml` — YAML key naming convention verified
- Codebase: `app/assets/stylesheets/application.css` — `require_tree .` confirmed
- Phase docs: `89-CONTEXT.md`, `89-UI-SPEC.md` — all locked decisions and SCSS values

### Secondary (MEDIUM confidence)

- Codebase: `test/controllers/welcome_controller/root_path_test.rb` — test naming and assertion patterns

### Tertiary (LOW confidence)

- None

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — no new packages; all existing Rails infrastructure
- Architecture: HIGH — skip_before_action pattern verified in codebase; locale concern fully read
- Pitfalls: HIGH — derived from direct code reading, not speculation
- CSS values: HIGH — exact values from UI-SPEC, cross-referenced with landing.css.scss

**Research date:** 2026-05-19
**Valid until:** 2026-06-18 (stable Rails conventions; YAML structure unlikely to change)
