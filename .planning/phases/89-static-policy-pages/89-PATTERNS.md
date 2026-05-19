# Phase 89: Static Policy Pages - Pattern Map

**Mapped:** 2026-05-19
**Files analyzed:** 9
**Analogs found:** 9 / 9

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `app/controllers/pages_controller.rb` | controller | request-response | `app/controllers/welcome_controller.rb` | exact |
| `app/views/pages/privacy.html.erb` | view | request-response | `app/views/welcome/_landing.html.erb` | exact |
| `app/views/pages/terms.html.erb` | view | request-response | `app/views/welcome/_landing.html.erb` | exact |
| `app/assets/stylesheets/pages.css.scss` | config | transform | `app/assets/stylesheets/landing.css.scss` | exact |
| `config/routes.rb` | config | request-response | `config/routes.rb` (existing) | self |
| `config/locales/ja.yml` | config | transform | `config/locales/ja.yml` `landing:` namespace (line 233) | self |
| `config/locales/en.yml` | config | transform | `config/locales/en.yml` `landing:` namespace (line 233) | self |
| `test/controllers/privacy_controller_test.rb` | test | request-response | `test/controllers/welcome_controller/root_path_test.rb` | exact |
| `test/controllers/terms_controller_test.rb` | test | request-response | `test/controllers/welcome_controller/root_path_test.rb` | exact |

---

## Pattern Assignments

### `app/controllers/pages_controller.rb` (controller, request-response)

**Analog:** `app/controllers/welcome_controller.rb`

**Full analog** (lines 1-17):
```ruby
class WelcomeController < ApplicationController
  skip_before_action :authenticate_user!, only: :index

  def index
    return unless user_signed_in?

    @portal = current_user.portals.first
  end

  def save_state
    # ...
  end
end
```

**Core pattern to copy — PagesController uses the same `skip_before_action` but without `only:` (both actions public, no instance variables needed):**
```ruby
class PagesController < ApplicationController
  skip_before_action :authenticate_user!

  def privacy
  end

  def terms
  end
end
```

Key difference from WelcomeController: no `only:` qualifier; no instance variable assignment (pages render static YAML content only).

---

### `app/views/pages/privacy.html.erb` (view, request-response)

**Analog:** `app/views/welcome/_landing.html.erb`

**Lang switcher pattern** (lines 2-5 of analog — adapt by replacing `root_path` with `privacy_path`):
```erb
<div class="landing-lang-switcher">
  <%= link_to "日本語", root_path(locale: 'ja'), class: "landing-lang-link #{'landing-lang-link--active' if I18n.locale == :ja}" %>
  <%= link_to "English", root_path(locale: 'en'), class: "landing-lang-link #{'landing-lang-link--active' if I18n.locale == :en}" %>
</div>
```

**Adapted lang switcher for privacy.html.erb** (add `aria: { current: }` per UI-SPEC accessibility contract):
```erb
<div class="landing-lang-switcher">
  <%= link_to "日本語", privacy_path(locale: 'ja'),
        class: "landing-lang-link #{'landing-lang-link--active' if I18n.locale == :ja}",
        aria: { current: (I18n.locale == :ja ? 'true' : nil) } %>
  <%= link_to "English", privacy_path(locale: 'en'),
        class: "landing-lang-link #{'landing-lang-link--active' if I18n.locale == :en}",
        aria: { current: (I18n.locale == :en ? 'true' : nil) } %>
</div>
```

**i18n call pattern** (analog lines 7-9 — `t()` backed by YAML, no hardcoded strings):
```erb
<p class="landing-eyebrow"><%= t('landing.hero.eyebrow') %></p>
<h1><%= t('landing.hero.title') %></h1>
<p class="landing-description"><%= t('landing.hero.description') %></p>
```

**Full view structure to build:**
```erb
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
        <%= simple_format(t("pages.privacy.sections.#{section}.body")) %>
      </section>
    <% end %>
  </article>
</main>
```

Note: Use `simple_format(t(...))` rather than `<p><%= t(...) %></p>` to handle multi-paragraph body text safely (converts `\n\n` to paragraph breaks, auto-escapes).

---

### `app/views/pages/terms.html.erb` (view, request-response)

**Analog:** `app/views/welcome/_landing.html.erb`

Same pattern as privacy.html.erb with these substitutions:
- `privacy_path` → `terms_path`
- `pages.privacy.*` → `pages.terms.*`
- Section loop: `%w[acceptable_use availability termination]`

```erb
<main class="landing-page">
  <div class="landing-lang-switcher">
    <%= link_to "日本語", terms_path(locale: 'ja'),
          class: "landing-lang-link #{'landing-lang-link--active' if I18n.locale == :ja}",
          aria: { current: (I18n.locale == :ja ? 'true' : nil) } %>
    <%= link_to "English", terms_path(locale: 'en'),
          class: "landing-lang-link #{'landing-lang-link--active' if I18n.locale == :en}",
          aria: { current: (I18n.locale == :en ? 'true' : nil) } %>
  </div>

  <div class="policy-back-link">
    <%= link_to t('pages.terms.back_home'), root_path %>
  </div>

  <article class="policy-content">
    <h1><%= t('pages.terms.title') %></h1>

    <% %w[acceptable_use availability termination].each do |section| %>
      <section>
        <h2 class="policy-section-heading"><%= t("pages.terms.sections.#{section}.heading") %></h2>
        <%= simple_format(t("pages.terms.sections.#{section}.body")) %>
      </section>
    <% end %>
  </article>
</main>
```

---

### `app/assets/stylesheets/pages.css.scss` (config, transform)

**Analog:** `app/assets/stylesheets/landing.css.scss`

**SCSS structure pattern** (analog lines 1-30 — `.landing-*` classes with nested SCSS, media query at end):
```scss
.landing-page {
  margin: 24px auto 40px;
  max-width: 960px;
}

.landing-lang-link {
  // ...
  &:hover {
    background: #e8f0fe;
    color: #2f6feb;
  }
}

@media (max-width: 767px) {
  .landing-page {
    margin-top: 14px;
  }
}
```

**New file — `.policy-*` classes only (exact values from UI-SPEC):**
```scss
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

No manifest edits required — `application.css` uses `require_tree .` which auto-includes this file.

---

### `config/routes.rb` (config, request-response)

**Analog:** `config/routes.rb` itself (lines 1-70)

**Insertion point** — add two routes inside the `unless ARGV.first =~ /^dad:setup(:.+)?/` block (lines 3-18), immediately after the two_factor and email_registration routes (before line 19 which closes the `unless` block):

```ruby
# Insert after line 17 (users/email_registration routes), before line 18 (end of unless block):
get 'privacy', to: 'pages#privacy'
get 'terms',   to: 'pages#terms'
```

The `unless` block currently ends at line 18. Place the two new routes on lines 18-19, pushing the `end` to line 20. This generates named helpers `privacy_path` and `terms_path` automatically (no `as:` needed).

---

### `config/locales/ja.yml` (config, transform)

**Analog:** `config/locales/ja.yml` `landing:` namespace (line 233)

**Existing `landing:` structure to mirror** (lines 233-272 of analog):
```yaml
  landing:
    header:
      subtitle: 情報整理を、やさしく
    hero:
      eyebrow: はじめての方へ
      title: 情報整理を、もっとシンプルに
    values:
      capture:
        title: 思いついたらすぐ保存
        body: ...
```

**New `pages:` namespace to add** (2-space indentation throughout, same depth as `landing:`):
```yaml
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

Body text is substantive prose (required for X Developer Portal review). Multi-paragraph bodies use `\n\n` within the quoted string; `simple_format` in the view handles paragraph rendering.

---

### `config/locales/en.yml` (config, transform)

**Analog:** `config/locales/en.yml` `landing:` namespace (line 233)

**Existing `landing:` structure** (lines 233-244 of analog):
```yaml
  landing:
    header:
      subtitle: Organize information with ease
    hero:
      eyebrow: For first-time users
      title: Simplify your daily information flow
    values:
      capture:
        title: Save anything, instantly
        body: Clip bookmarks, jot notes, and capture ideas the moment they strike ...
```

**New `pages:` namespace to add** (identical structure, English content):
```yaml
  pages:
    privacy:
      title: Privacy Policy
      back_home: "← Back to home"
      sections:
        data_collected:
          heading: Information We Collect
          body: "..."
        x_login:
          heading: Purpose of X (Twitter) Login
          body: "..."
        email_handling:
          heading: Email Address Handling
          body: "..."
        data_retention:
          heading: Data Retention
          body: "..."
        contact:
          heading: Contact
          body: "..."
    terms:
      title: Terms of Service
      back_home: "← Back to home"
      sections:
        acceptable_use:
          heading: Acceptable Use
          body: "..."
        availability:
          heading: Service Availability
          body: "..."
        termination:
          heading: Account Termination
          body: "..."
```

---

### `test/controllers/privacy_controller_test.rb` (test, request-response)

**Analog:** `test/controllers/welcome_controller/root_path_test.rb`

**Full analog** (lines 1-70):
```ruby
require 'test_helper'

class WelcomeController::RootPathTest < ActionDispatch::IntegrationTest
  def test_未ログインでrootはランディングページを表示する
    get root_path
    assert_response :success
    assert_select '.landing-page', count: 1
  end

  def test_rootは英語ロケールで英語見出しを表示する
    get root_path, headers: { 'Accept-Language' => 'en-US,en;q=0.9,ja;q=0.8' }
    assert_response :success
    assert_select 'html[lang=?]', 'en'
    assert_includes response.body, 'Simplify your daily information flow'
  end
end
```

**Key patterns:**
- Class inherits `ActionDispatch::IntegrationTest` (not `include Devise::Test::IntegrationHelpers` — not needed for unauthenticated tests)
- Japanese method names: `test_未認証で...`
- `get path` + `assert_response :success` + `assert_select` / `assert_includes`
- Locale via `params: { locale: 'en' }` (not Accept-Language header, simpler for policy pages)

**New file pattern:**
```ruby
require 'test_helper'

class PrivacyControllerTest < ActionDispatch::IntegrationTest
  def test_未認証でprivacyは200を返す
    get privacy_path
    assert_response :success
  end

  def test_privacyはランディングページ構造を使う
    get privacy_path
    assert_response :success
    assert_select 'main.landing-page', count: 1
  end

  def test_privacyは日本語ロケールで日本語タイトルを表示する
    get privacy_path
    assert_response :success
    assert_select 'h1', text: 'プライバシーポリシー'
  end

  def test_privacyは英語ロケールで英語タイトルを表示する
    get privacy_path, params: { locale: 'en' }
    assert_response :success
    assert_select 'h1', text: 'Privacy Policy'
  end

  def test_privacyは認証リダイレクトしない
    get privacy_path
    assert_response :success
    refute_equal new_user_session_path, response.location
  end

  def test_privacyはセクション見出しを含む
    get privacy_path
    assert_response :success
    assert_select 'h2.policy-section-heading'
  end
end
```

---

### `test/controllers/terms_controller_test.rb` (test, request-response)

**Analog:** `test/controllers/welcome_controller/root_path_test.rb`

Same pattern as privacy_controller_test.rb with substitutions:
- `PrivacyControllerTest` → `TermsControllerTest`
- `privacy_path` → `terms_path`
- `'プライバシーポリシー'` → `'利用規約'`
- `'Privacy Policy'` → `'Terms of Service'`

```ruby
require 'test_helper'

class TermsControllerTest < ActionDispatch::IntegrationTest
  def test_未認証でtermsは200を返す
    get terms_path
    assert_response :success
  end

  def test_termsはランディングページ構造を使う
    get terms_path
    assert_response :success
    assert_select 'main.landing-page', count: 1
  end

  def test_termsは日本語ロケールで日本語タイトルを表示する
    get terms_path
    assert_response :success
    assert_select 'h1', text: '利用規約'
  end

  def test_termsは英語ロケールで英語タイトルを表示する
    get terms_path, params: { locale: 'en' }
    assert_response :success
    assert_select 'h1', text: 'Terms of Service'
  end

  def test_termsは認証リダイレクトしない
    get terms_path
    assert_response :success
    refute_equal new_user_session_path, response.location
  end

  def test_termsはセクション見出しを含む
    get terms_path
    assert_response :success
    assert_select 'h2.policy-section-heading'
  end
end
```

---

## Shared Patterns

### Auth Bypass
**Source:** `app/controllers/welcome_controller.rb` line 2
**Apply to:** `app/controllers/pages_controller.rb`
```ruby
skip_before_action :authenticate_user!
```
PagesController skips without `only:` (both actions public). WelcomeController uses `only: :index` because `save_state` requires auth.

### Lang Switcher CSS Classes (reuse, no modification)
**Source:** `app/assets/stylesheets/landing.css.scss` lines 6-30
**Apply to:** Both view templates — use existing `.landing-lang-switcher`, `.landing-lang-link`, `.landing-lang-link--active` classes
```scss
.landing-lang-switcher { display: flex; gap: 8px; justify-content: flex-end; margin-bottom: 12px; }
.landing-lang-link { color: #4f6b95; font-size: 13px; font-weight: 600; ... }
.landing-lang-link--active { background: #e8f0fe; color: #2f6feb; }
```

### Page Wrapper (reuse, no modification)
**Source:** `app/assets/stylesheets/landing.css.scss` lines 1-4
**Apply to:** Both view templates — wrap content in `<main class="landing-page">`
```scss
.landing-page { margin: 24px auto 40px; max-width: 960px; }
```

### i18n t() Call Pattern
**Source:** `app/views/welcome/_landing.html.erb` lines 7-9
**Apply to:** All string literals in both view templates
```erb
<%= t('pages.privacy.title') %>
<%= t("pages.privacy.sections.#{section}.heading") %>
```
No hardcoded visible strings in views.

### YAML Namespace Convention
**Source:** `config/locales/ja.yml` line 233 (`landing:` namespace)
**Apply to:** Both locale files — add `pages:` at same indentation depth (2 spaces under locale key)
```yaml
ja:
  landing:    # existing — 2-space indent
    ...
  pages:      # new — same 2-space indent
    privacy:
      ...
```

### Integration Test Class Naming
**Source:** `test/controllers/welcome_controller/root_path_test.rb` line 3
**Apply to:** Both new test files
```ruby
class PrivacyControllerTest < ActionDispatch::IntegrationTest
```
Flat class name (not namespaced under `PagesController::`) — consistent with flat file placement in `test/controllers/`.

---

## No Analog Found

All files in this phase have close analogs. No entries.

---

## Metadata

**Analog search scope:** `app/controllers/`, `app/views/welcome/`, `app/assets/stylesheets/`, `config/routes.rb`, `config/locales/`, `test/controllers/welcome_controller/`
**Files scanned:** 7 analog files read
**Pattern extraction date:** 2026-05-19
