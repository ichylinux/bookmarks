# Phase 16: Core Shell & Shared Messages Translation - Pattern Map

**Mapped:** 2026-05-01
**Files analyzed:** 7 (2 yml modify, 2 view modify, 1 controller modify, 2 new tests)
**Analogs found:** 7 / 7

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `config/locales/ja.yml` (MODIFY) | yml-data | static-catalog | `config/locales/ja.yml` (Phase 15 sections — `messages.*`, `two_factor.*`, `preferences.index.*`) | exact (same file, additive) |
| `config/locales/en.yml` (MODIFY) | yml-data | static-catalog | `config/locales/en.yml` (Phase 15 mirror structure) | exact (same file, additive) |
| `app/views/layouts/application.html.erb` (MODIFY) | view (layout) | request-response | `app/views/preferences/index.html.erb` (Phase 15 i18nified view) | role-match (both server-rendered ERB consuming `t()` absolute keys + lazy keys) |
| `app/views/common/_menu.html.erb` (MODIFY) | view (partial) | request-response | `app/views/preferences/index.html.erb` (Phase 15 i18nified view) | role-match (partial consuming `t()` calls) |
| `app/controllers/notes_controller.rb` (MODIFY, line 8) | controller | request-response | `app/controllers/users/two_factor_setup_controller.rb` (`t('two_factor.enabled')` absolute-keyed flash) | exact (absolute-keyed flash in redirect_to) |
| `test/i18n/locales_parity_test.rb` (NEW) | test (unit) | static-catalog | (no existing `test/i18n/`) — closest is `test/controllers/preferences_controller_test.rb` for Minitest conventions only | no-analog for structure; convention-match for naming |
| `test/i18n/rails_i18n_smoke_test.rb` (NEW) | test (unit) | static-catalog | `test/controllers/two_factor_setup_controller_test.rb:16` (`I18n.t(...)` direct lookup pattern) | partial — same `I18n.t` lookup form |
| `test/controllers/application_controller_test.rb` (EXTEND) | test (integration) | request-response | itself (Phase 14 VERI18N-01 tests) + Phase 15 `test_設定画面が日本語ロケールで日本語表示される` | exact (extending same file with sibling locale-rendering assertions) |
| `test/controllers/notes_controller_test.rb` (EXTEND) | test (integration) | request-response | Phase 15 `test_localeをjaに更新できる` (sign_in + `update!(locale:)` + assertion against locale-specific text) | role-match |

## Pattern Assignments

### `config/locales/ja.yml` (yml-data, additive)

**Analog:** Phase 15 sections of the same file (lines 27-28 `messages:` top-level + lines 49-59 `preferences.index.*` lazy lookup).

**Top-level absolute-keyed namespace pattern** (`messages.confirm_delete` precedent — D-01 mirror) — `config/locales/ja.yml:27-28`:
```yaml
  messages:
    confirm_delete: '%{name} を削除します。よろしいですか？'
```

**New top-level namespaces to add** (per RESEARCH.md, immediately under `ja:` at the same indent as `messages:`, `two_factor:`, `preferences:`):
```yaml
  nav:
    home: ホーム
    note: Note               # native brand label per D-06 (kept identical in en)
    preferences: 設定
    bookmarks: ブックマーク
    todos: タスク
    calendars: カレンダー
    feeds: フィード
    sign_out: ログアウト
    menu_aria: メニュー

  flash:
    errors:
      generic: エラーが発生しました
```

**Anti-pattern (do NOT introduce):** `errors.messages.*` or `activerecord.errors.messages.*` blocks — these would silently shadow rails-i18n defaults (RESEARCH.md Pitfall 3; verified absent via `grep 'errors:' config/locales/*.yml`).

---

### `config/locales/en.yml` (yml-data, additive — must mirror ja keys exactly)

**Analog:** Phase 15 sections of the same file (the entire en.yml is a structural mirror of ja.yml; `messages.confirm_delete: 'Delete %{name}. Are you sure?'` at line 16 is the precedent for top-level absolute-keyed shared strings).

**Mirror pattern** — `config/locales/en.yml:15-16`:
```yaml
  messages:
    confirm_delete: 'Delete %{name}. Are you sure?'
```

**New keys to add** (mirror ja structure exactly — parity test enforces this):
```yaml
  nav:
    home: Home
    note: Note
    preferences: Preferences
    bookmarks: Bookmarks
    todos: Tasks
    calendars: Calendars
    feeds: Feeds
    sign_out: Sign out
    menu_aria: Menu

  flash:
    errors:
      generic: Something went wrong.
```

---

### `app/views/layouts/application.html.erb` (view, layout)

**Analog:** `app/views/preferences/index.html.erb` (Phase 15) for the `t()` call form. Same file (current state of layout) for context preservation around drawer/`drawer_ui?` gating.

**Current hardcoded literals** — `app/views/layouts/application.html.erb:23, 35-41`:
```erb
<button class="hamburger-btn" aria-label="メニュー"></button>
...
<%= link_to 'Home', root_path %>
<%= link_to '設定', preferences_path %>
<%= link_to 'ブックマーク', bookmarks_path %>
<%= link_to 'タスク', todos_path %>
<%= link_to 'カレンダー', calendars_path %>
<%= link_to 'フィード', feeds_path %>
<%= link_to 'ログアウト', destroy_user_session_path, method: 'delete' %>
```

**Substitution pattern (D-01 absolute key — NOT lazy lookup, because nav is shared across layout + `_menu`):**
```erb
<button class="hamburger-btn" aria-label="<%= t('nav.menu_aria') %>"></button>
...
<%= link_to t('nav.home'), root_path %>
<%= link_to t('nav.preferences'), preferences_path %>
<%= link_to t('nav.bookmarks'), bookmarks_path %>
<%= link_to t('nav.todos'), todos_path %>
<%= link_to t('nav.calendars'), calendars_path %>
<%= link_to t('nav.feeds'), feeds_path %>
<%= link_to t('nav.sign_out'), destroy_user_session_path, method: 'delete' %>
```

**Keep untranslated** (native-brand rule, parallel to Phase 15 D-02 native-label rule):
- `<title>Bookmarks</title>` (line 4)
- `alt="Bookmarks"` (line 19)
- `link_to 'Bookmarks', root_path, class: 'head-title'` (line 20)

---

### `app/views/common/_menu.html.erb` (view, partial)

**Analog:** `app/views/preferences/index.html.erb` (Phase 15) for `t()` form; layout above for the *same* `nav.*` keys reused.

**Current hardcoded literals** — `app/views/common/_menu.html.erb:35-47`:
```erb
<li><%= link_to 'Home', root_path %></li>
<% if current_user.preference&.use_note? %>
  <li><%= link_to 'Note', root_path(tab: 'notes') %></li>
<% end %>
...
<div><%= link_to '設定', preferences_path %></div>
<div><%= link_to 'ブックマーク', bookmarks_path %></div>
<div><%= link_to 'タスク', todos_path %></div>
<div><%= link_to 'カレンダー', calendars_path %></div>
<div><%= link_to 'フィード', feeds_path %></div>
<div><%= link_to 'ログアウト', destroy_user_session_path, method: 'delete' %></div>
```

**Substitution pattern (same shared `nav.*` absolute keys):**
```erb
<li><%= link_to t('nav.home'), root_path %></li>
<% if current_user.preference&.use_note? %>
  <li><%= link_to t('nav.note'), root_path(tab: 'notes') %></li>
<% end %>
...
<div><%= link_to t('nav.preferences'), preferences_path %></div>
<div><%= link_to t('nav.bookmarks'), bookmarks_path %></div>
<div><%= link_to t('nav.todos'), todos_path %></div>
<div><%= link_to t('nav.calendars'), calendars_path %></div>
<div><%= link_to t('nav.feeds'), feeds_path %></div>
<div><%= link_to t('nav.sign_out'), destroy_user_session_path, method: 'delete' %></div>
```

**Anti-pattern (do NOT use lazy lookup `t('.home')` here):** the simple-theme menu is at `app/views/common/_menu.html.erb`, so lazy lookup would resolve to `common._menu.home` (or with leading underscore quirks, `common.menu.home`) — which would diverge from the layout's path. Phase 15 lazy-lookup template-path pitfall (Plan 15-02 → 15-03 fix-up) explicitly warns against this. Use absolute `t('nav.*')` keys.

---

### `app/controllers/notes_controller.rb` (controller, single-line flash substitution)

**Analog (exact pattern):** `app/controllers/users/two_factor_setup_controller.rb:15, 18, 25` — absolute-keyed flash via `t('namespace.key')` inline at the `redirect_to` / `flash.now[:alert]` call site.

**Reference excerpt** — `app/controllers/users/two_factor_setup_controller.rb:14-19`:
```ruby
def enable
  if current_user.validate_and_consume_otp!(params[:otp_attempt])
    current_user.enable_two_factor!
    redirect_to users_two_factor_setup_path, notice: t('two_factor.enabled')
  else
    @qr_code = generate_qr_code(current_user.otp_provisioning_uri)
    flash.now[:alert] = t('two_factor.invalid_code')
```

**Current hardcoded literal** — `app/controllers/notes_controller.rb:8`:
```ruby
redirect_to root_path(tab: 'notes'), alert: @note.errors.full_messages.to_sentence.presence || 'エラーが発生しました'
```

**Substitution pattern (D-03 — single shared `flash.errors.generic`):**
```ruby
redirect_to root_path(tab: 'notes'),
            alert: @note.errors.full_messages.to_sentence.presence || t('flash.errors.generic')
```

**Critical:** `t()` MUST be inlined at the call site (per-request `I18n.locale`). Do NOT extract to a class-level constant — RESEARCH.md Pitfall 5 (`MESSAGE = t(...)` at load time freezes to `:ja`).

---

### `test/i18n/locales_parity_test.rb` (NEW — unit test)

**Analog:** No existing `test/i18n/` directory. Closest convention sources:
- `test/controllers/preferences_controller_test.rb:1-3` for `require 'test_helper'` + class header (but use `ActiveSupport::TestCase` not `IntegrationTest` since this is a pure YAML structural test).
- Japanese test method names per CONVENTIONS.md (`test_jaとenのキー集合が一致する`).

**Reference for `require 'test_helper'` + Minitest class header** — `test/controllers/preferences_controller_test.rb:1-3`:
```ruby
require 'test_helper'

class PreferencesControllerTest < ActionDispatch::IntegrationTest
```

**Pattern to use (RESEARCH.md "Code Examples" — verbatim):**
```ruby
# test/i18n/locales_parity_test.rb
require 'test_helper'

class LocalesParityTest < ActiveSupport::TestCase
  # Recursively flatten a nested hash into dotted keys.
  def flatten_keys(hash, prefix = nil)
    hash.flat_map do |key, value|
      path = [prefix, key].compact.join('.')
      value.is_a?(Hash) ? flatten_keys(value, path) : [path]
    end
  end

  def test_jaとenのキー集合が一致する
    ja = YAML.load_file(Rails.root.join('config/locales/ja.yml'))['ja']
    en = YAML.load_file(Rails.root.join('config/locales/en.yml'))['en']

    ja_keys = flatten_keys(ja).sort
    en_keys = flatten_keys(en).sort

    only_in_ja = ja_keys - en_keys
    only_in_en = en_keys - ja_keys

    assert_empty only_in_ja, "ja.yml にのみ存在するキー: #{only_in_ja.inspect}"
    assert_empty only_in_en, "en.yml にのみ存在するキー: #{only_in_en.inspect}"
  end
end
```

**Note:** Rails autoloads any `*_test.rb` under `test/`, so the new `test/i18n/` directory needs no manifest edit.

---

### `test/i18n/rails_i18n_smoke_test.rb` (NEW — unit test)

**Analog:** `test/controllers/two_factor_setup_controller_test.rb:16` (`I18n.t('two_factor.status_enabled')` lookup pattern) — though here we use `I18n.with_locale` to switch locales inline.

**Reference excerpt** — `test/controllers/two_factor_setup_controller_test.rb:14-17`:
```ruby
def test_show_renders_enabled_when_2fa_enabled
  user.enable_two_factor!
  sign_in user
  get users_two_factor_setup_path
  assert_response :success
  assert_match I18n.t('two_factor.status_enabled'), response.body
```

**Pattern to use (D-04 verification — rails-i18n auto-load smoke):**
```ruby
require 'test_helper'

class RailsI18nSmokeTest < ActiveSupport::TestCase
  def test_railsI18nのjaメッセージが解決される
    ja_blank = I18n.with_locale(:ja) { I18n.t('errors.messages.blank') }
    assert_equal 'を入力してください', ja_blank
  end

  def test_railsI18nのenメッセージが解決される
    en_blank = I18n.with_locale(:en) { I18n.t('errors.messages.blank') }
    assert_equal "can't be blank", en_blank
  end
end
```

If A1 (auto-load assumption) is wrong, this test fails — the planner then adds an explicit `config.i18n.load_path` entry. Verifies D-04 cheaply.

---

### `test/controllers/application_controller_test.rb` (EXTEND — integration test)

**Analog:** Same file (Phase 14 VERI18N-01 tests, lines 6-39) + Phase 15 `test_設定画面が日本語ロケールで日本語表示される` (`preferences_controller_test.rb:153-184`).

**Reference excerpt — locale-update + sign_in + locale-specific assertion** — `test/controllers/preferences_controller_test.rb:153-166`:
```ruby
def test_設定画面が日本語ロケールで日本語表示される
  user.preference.update!(locale: 'ja')
  sign_in user
  get preferences_path

  assert_response :success
  assert_select 'html[lang=?]', 'ja'
  assert_select 'th', text: 'テーマ'
  assert_select 'th', text: '言語'
  assert_select 'th', text: '文字サイズ'
  assert_select 'option', text: 'モダン'
  assert_select 'option', text: '大'
  assert_select 'input[type=submit][value=?]', '保存'
end
```

**Reference excerpt — existing `application_controller_test.rb` Phase 14 pattern** — lines 6-12:
```ruby
def test_保存済みlocaleがenのユーザは英語でレンダリングされる
  user.preference.update!(locale: 'en')
  sign_in user
  get root_path
  assert_response :success
  assert_select 'html[lang=?]', 'en'
end
```

**New tests to add (extend with chrome-string assertions):**
```ruby
def test_chromeはja_localeでホームと設定とメニューariaを含む
  user.preference.update!(locale: 'ja')
  sign_in user
  get root_path
  assert_response :success
  # drawer_ui? branch (modern/classic theme — fixture default)
  assert_select 'a', text: 'ホーム'
  assert_select 'a', text: '設定'
  assert_select 'button.hamburger-btn[aria-label=?]', 'メニュー'
end

def test_chromeはen_localeでHomeとPreferencesとMenuariaを含む
  user.preference.update!(locale: 'en')
  sign_in user
  get root_path
  assert_response :success
  assert_select 'a', text: 'Home'
  assert_select 'a', text: 'Preferences'
  assert_select 'button.hamburger-btn[aria-label=?]', 'Menu'
end
```

**Pre-flight check (RESEARCH.md A4):** verify `test/fixtures/preferences.yml` default theme is non-`'simple'` so drawer renders. If `theme == 'simple'`, set `user.preference.update!(theme: 'modern', locale: 'ja')` first and assert against `_menu.html.erb` DOM (`ul.navigation` / `li > a`) instead of drawer.

---

### `test/controllers/notes_controller_test.rb` (EXTEND — integration test)

**Analog:** existing same file (lines 24-34, `test_blank_body_does_not_create` — already exercises the fallback alert path; just stops at `flash[:alert].present?`).

**Reference excerpt** — `test/controllers/notes_controller_test.rb:24-34`:
```ruby
def test_blank_body_does_not_create
  sign_in @user

  assert_no_difference('Note.count') do
    post notes_path, params: { note: { body: '   ' } }
  end

  assert_redirected_to root_path(tab: 'notes')
  follow_redirect!
  assert_predicate flash[:alert], :present?
end
```

**Cross-analog (locale switching pattern)** — `test/controllers/preferences_controller_test.rb:103-114`:
```ruby
def test_localeをjaに更新できる
  user.preference.update!(locale: nil)
  sign_in user
  patch preference_path(user), params: {
    user: {
      preference_attributes: preference_params(locale: 'ja').merge(id: user.preference.id)
    }
  }

  assert_response :redirect
  assert_equal 'ja', user.preference.reload.locale
end
```

**Substitution pattern — TRN-04 evidence (when full_messages happens to be blank, the fallback resolves per locale).** Note: Note model validates `body` length and presence; `errors.full_messages` for body presence is NOT empty (rails-i18n ja: "本文を入力してください"), so to exercise the **fallback** branch, the body must be present-but-otherwise-invalid (e.g., over-length triggers `full_messages`, while certain edge cases hit `presence` → blank `to_sentence` → fallback). For Phase 16, the simpler approach is to assert that `flash.errors.generic` resolves correctly in each locale via `I18n.t`, without depending on Note validation internals:

```ruby
def test_flash_errors_genericはjaで日本語になる
  ja = I18n.with_locale(:ja) { I18n.t('flash.errors.generic') }
  assert_equal 'エラーが発生しました', ja
end

def test_flash_errors_genericはenで英語になる
  en = I18n.with_locale(:en) { I18n.t('flash.errors.generic') }
  assert_equal 'Something went wrong.', en
end
```

(Planner may instead extend `test_blank_body_does_not_create` to assert the alert is `t('flash.errors.generic')` in ja, mirroring the two_factor approach `assert_match I18n.t('two_factor.status_enabled'), response.body`.)

---

## Shared Patterns

### Top-level absolute-keyed translation (D-01)

**Source:** `config/locales/ja.yml:27-28` + `app/views/preferences/index.html.erb` (uses `t('messages.confirm_delete', name: ...)` precedent across `bookmarks/feeds/todos/calendars` views).

**Apply to:** All `nav.*` and `flash.*` strings in Phase 16 (layout, menu, notes_controller).

**Pattern:**
```yaml
# top-level under root locale, sibling of activerecord, messages, two_factor, preferences
nav: { ... }
flash:
  errors: { generic: ... }
```
```erb
<%= t('nav.home') %>
```
```ruby
alert: t('flash.errors.generic')
```

### Sign-in-then-locale-update integration test scaffold (Phase 14/15 carry-forward)

**Source:** `test/controllers/preferences_controller_test.rb:153-166` (Phase 15) + `test/controllers/application_controller_test.rb:6-12` (Phase 14).

**Apply to:** All Phase 16 integration tests for TRN-01.

**Pattern:**
```ruby
def test_<日本語名>
  user.preference.update!(locale: '<ja|en>')
  sign_in user
  get <path>
  assert_response :success
  assert_select 'html[lang=?]', '<ja|en>'
  # locale-specific assertions
end
```

### `t()` always at call site, never at load time

**Source:** `app/controllers/users/two_factor_setup_controller.rb:15, 18, 25` — all three `t('two_factor.*')` calls are inline at request-handling points; nowhere is a constant pre-frozen.

**Apply to:** `app/controllers/notes_controller.rb:8` substitution. Do NOT introduce `GENERIC_ERROR = t('flash.errors.generic')` — the value would freeze to the boot-time locale (`:ja`) and en users would never see English.

### Wave-order discipline (yml-first → views/controllers → tests)

**Source:** Phase 15 retrospective (Plan 15-02 → 15-03 fix-up commit `9a5bbdb`).

**Apply to:** All of Phase 16. Each commit must leave the app in a state where: (a) yml has every key views reference, (b) parity test passes, (c) views/controllers don't reference keys that don't exist yet. Otherwise dev-mode renders `translation missing: ja.nav.home` literally into HTML (RESEARCH.md Pitfall 2).

### Native-label preservation (D-06 carry-forward from Phase 15 D-02)

**Source:** `app/views/preferences/index.html.erb` (Phase 15) — `LOCALE_OPTIONS = { '自動' => nil, '日本語' => 'ja', 'English' => 'en' }` stays native in both locales.

**Apply to:** Phase 16's `nav.note` (kept as `Note` in both ja and en) and the brand strings `<title>Bookmarks</title>`, `alt="Bookmarks"`, `link_to 'Bookmarks'` (kept untranslated).

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `test/i18n/locales_parity_test.rb` | test (unit, structural-yaml) | static-catalog | No prior `test/i18n/` directory; no prior `ActiveSupport::TestCase`-style structural YAML tests. Convention borrowed from `test_helper` boilerplate; pattern body is fresh per RESEARCH.md "Code Examples". |
| `test/i18n/rails_i18n_smoke_test.rb` | test (unit, gem-load smoke) | static-catalog | No prior smoke test for rails-i18n auto-load. Pattern is fresh; nearest similarity is `I18n.t` direct lookup in `test/controllers/two_factor_setup_controller_test.rb:16`. |

(Both fall back to RESEARCH.md "Code Examples" section for full implementations.)

## Metadata

**Analog search scope:**
- `app/controllers/` (notes, two_factor_setup, application)
- `app/views/layouts/`, `app/views/common/`, `app/views/preferences/`
- `config/locales/{ja,en}.yml`
- `test/controllers/` (preferences, notes, application, two_factor_setup)
- `.planning/phases/15-language-preference/15-{02,03}-SUMMARY.md`
- `.planning/phases/16-core-shell-and-shared-messages-translation/16-{CONTEXT,RESEARCH}.md`

**Files scanned:** 12 (read in full or targeted-range)
**Pattern extraction date:** 2026-05-01

## PATTERN MAPPING COMPLETE
