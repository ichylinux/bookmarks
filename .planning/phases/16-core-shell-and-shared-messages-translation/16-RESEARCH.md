---
phase: 16
phase_name: Core Shell & Shared Messages Translation
phase_slug: core-shell-and-shared-messages-translation
milestone: v1.4
created: 2026-05-01
status: research-complete
---

# Phase 16: Core Shell & Shared Messages Translation — Research

**Researched:** 2026-05-01
**Domain:** Rails 8.1 i18n — chrome-layer translation (layouts, drawer/menu nav, controller flash, validation defaults)
**Confidence:** HIGH

## Summary

Phase 16 translates the app **chrome layer** (top-level layout + drawer + simple-theme menu + the single hardcoded controller flash fallback) and activates `rails-i18n` so `errors.messages.*` / `activerecord.errors.messages.*` produce localized validation messages in both `:ja` and `:en`. All major decisions are LOCKED in 16-CONTEXT.md (D-01..D-06); the planner's remaining work is mechanical: inventory hardcode, choose key namespace for non-flash shell strings, sequence yml-first/views-second waves, and add a parity test.

The hardcoded literal sweep finds **only three files** with chrome-layer Japanese strings (`app/views/layouts/application.html.erb`, `app/views/common/_menu.html.erb`, `app/controllers/notes_controller.rb:8`). The `Bookmarks` brand appearing twice in the layout (`<title>`, `head-title` link) should remain untranslated per the native-brand rule. The `'メニュー'` ARIA label is the only chrome ARIA string. Shared form-action buttons (`保存` / `登録` / `更新` / `キャンセル`) appearing in feature `_form.html.erb` partials are **out of scope** (Phase 17) — confirmed by inspection of `app/views/{bookmarks,calendars,feeds,todos}/_form.html.erb`.

`rails-i18n 8.1.0` is already in `Gemfile.lock` (auto-loaded by Bundler) and `available_locales = %i[ja en]` is set in `config/application.rb` — activation is essentially a verification exercise plus a smoke test that triggering a `presence: true` validation produces a localized message in each locale.

**Primary recommendation:** Hybrid namespace — top-level `nav.*` for nav strings (shared between layout drawer and `common/_menu`); top-level `flash.*` per D-01; lazy-anchored `t('.title')` style is unnecessary in this phase because nothing is single-use (the only single-use chrome string is the ARIA label `'メニュー'`, for which a top-level `nav.menu_aria` is simpler than spinning up `layouts.application.*`). Keep `<title>Bookmarks</title>` untranslated; translate only the ARIA label.

## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01: Top-level `flash.*` namespace, absolute keys.** All shared flash and alert strings live under a single top-level `flash.*` namespace in `ja.yml` / `en.yml`, accessed via absolute key (e.g. `t('flash.created', name: ...)`, `t('flash.destroyed', name: ...)`, `t('flash.errors.generic')`). Mirrors the existing `messages.confirm_delete` precedent. NOT lazy-lookup `t('.created')` per controller. Locale-file-anchored keys are immune to controller renames.

- **D-02: Interpolation passes record user-content directly via `name:`.** Flash strings that reference a record use `t('flash.X', name: @record.title)`. The interpolated value is user-entered content and is intentionally NOT translated. Identical pattern to `messages.confirm_delete`. **No `activerecord.models.*` (model-name) translation work in Phase 16.**

- **D-03: Single shared `flash.errors.generic` key for the generic error fallback.** The hardcoded `'エラーが発生しました'` literal in `app/controllers/notes_controller.rb:8` is replaced by `t('flash.errors.generic')`. ja: `'エラーが発生しました'`; en: `'Something went wrong.'` (final wording confirmed in plan). Same key reused for any future generic error fallback.

- **D-04: Activate `rails-i18n` for both ja and en.** `gem 'rails-i18n', '~> 8.0'` is already in `Gemfile`. Phase 16 ensures both `:ja` and `:en` validation message defaults are loaded. **`devise-i18n` is intentionally NOT activated in Phase 16** — deferred to Phase 18.

- **D-05: Lazy-lookup is still allowed for view-anchored partials.** The Phase 15 lesson stands — when a string belongs to a single view/partial, lazy lookup may be used **provided** the yml key exactly matches the view path. For Phase 16, absolute keys apply to flash/alert (D-01) and to nav strings shared across layout + drawer + menu. Per-partial cosmetics may use lazy lookup at the planner's discretion.

- **D-06: Native-label rule applies to in-shell language/script identity.** Phase 15's `自動 / 日本語 / English` precedent stands. Phase 16 introduces no new language-identity labels.

### Claude's Discretion (deferred to researcher/planner)

- Key namespace strategy for non-flash shell strings (nav, layout title, ARIA labels) — top-level vs lazy vs hybrid
- Phase 16 vs 17 boundary on shared form text
- Test coverage approach for TRN-01 / TRN-04 (Cucumber vs Minitest)
- Page title strategy (translate `<title>Bookmarks</title>` or keep as native brand)
- Hardcoded literal sweep — exhaustive inventory

### Deferred Ideas (OUT OF SCOPE for Phase 16)

- Feature surface (bookmarks/notes/todos/feeds/calendars) view + form bodies → Phase 17
- Devise auth pages and `devise-i18n` gem activation → Phase 18
- Two-factor view text (keys exist but Devise-flavored) → Phase 18
- JS-side strings (`data-*` attribute path) → Phase 17 TRN-05
- Shared form-action submit-button labels (`保存` / `登録` / `更新`) inside feature `_form.html.erb` partials → Phase 17

## Project Constraints (from CLAUDE.md)

- **Three suites must be green before phase complete:** `yarn run lint`, `bin/rails test`, `bundle exec rake dad:test` (Cucumber via custom rake task — never `bundle exec cucumber` directly).
- **Cucumber flakiness (2026-05-01):** scenarios share DB state; preference mutations (`theme = 'simple'`, `use_note: true`) leak. Re-run policy: a single failing run may be a pre-existing flake; consistent failure across two runs is a real regression. **Implication for Phase 16:** prefer Minitest integration tests (deterministic) over Cucumber for TRN-01 / TRN-04 verification. The phase should not introduce new Cucumber scenarios for chrome translation.

## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| TRN-01 | User can navigate the app shell in Japanese or English (layout, menu, drawer, shared buttons, breadcrumbs, ARIA, titles, placeholders) | Hardcode inventory below + namespace recommendation; Minitest assertions on `/` against drawer/menu strings in each locale |
| TRN-04 | User sees flash messages, controller alerts, and validation-facing labels in the active locale | D-01..D-04 (flash.* namespace + rails-i18n activation); generic flash key replaces `notes_controller.rb:8` literal |
| VERI18N-04 (Phase 18) | Translation keys present in both `ja.yml` and `en.yml` for every extracted string | Phase 16 must add a parity test as a foundation; Phase 18 will tighten coverage. (Per `REQUIREMENTS.md`, VERI18N-04 itself maps to Phase 18, but parity is success criterion 4 of Phase 16 in `ROADMAP.md`.) |

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|--------------|----------------|-----------|
| Locale resolution (`I18n.locale`) | API/Backend (Rails) | — | Already done in Phase 14 (`Localization` concern). Phase 16 is a pure consumer. |
| `<html lang>` rendering | Frontend Server (ERB) | — | Already done in Phase 14. |
| Nav / chrome string rendering | Frontend Server (ERB) | — | Server-side `t()` call sites in `app/views/layouts/**` and `app/views/common/**`. |
| Flash message rendering | API/Backend → Frontend Server | — | `redirect_to ..., alert: t('flash.errors.generic')` is rendered server-side at flash partial. |
| Validation message rendering | API/Backend (rails-i18n gem) | Frontend Server (form helpers) | rails-i18n provides defaults; Rails form helpers render `errors.full_messages`. |
| Translation key catalog | Configuration (yml) | — | `config/locales/ja.yml` + `config/locales/en.yml`. |

## Standard Stack

### Core (already installed — verify only)

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `rails-i18n` | 8.1.0 [VERIFIED: Gemfile.lock] | Bundles `errors.messages.*` and `activerecord.errors.messages.*` defaults for ja, en, and ~80 other locales | The de-facto canonical Rails i18n gem; the source of every non-English Rails error message in the ecosystem. [CITED: github.com/svenfuchs/rails-i18n] |
| Rails I18n API (`I18n.t`, `I18n.with_locale`) | Rails 8.1 built-in | Translation lookup, interpolation, fallback, lazy lookup | Standard Rails i18n. [CITED: guides.rubyonrails.org/i18n.html] |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `i18n-tasks` | not installed [VERIFIED: Gemfile.lock] | Static auditing of unused/missing keys | Deferred (REQUIREMENTS.md `I18NTOOL-01` — future). Phase 16 uses hand-rolled parity test instead. |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Hand-rolled parity test | `i18n-tasks` gem | gem provides `health` / `missing` / `unused` commands, but adds a Gemfile entry. Phase 16 has ~20 keys total — a 30-line minitest is sufficient and avoids the gem dependency tracked under `I18NTOOL-01`. |
| Top-level `nav.*` namespace | Lazy-anchored `layouts.application.nav.*` + `common.menu.nav.*` | Lazy duplicates "ホーム" / "Home" two ways. The same six labels appear in both layout drawer and simple-theme menu (verified by inventory below). Top-level wins on DRY. |
| Translate `<title>Bookmarks</title>` | `t('layouts.application.title')` defaulting to "Bookmarks" | The brand "Bookmarks" is the product name — kept as-is per native-brand rule (parallels Phase 15 D-02 "日本語/English are native-fixed"). [VERIFIED: app/views/layouts/application.html.erb:4 + L20 both show "Bookmarks" as brand string] |

**Installation:** None required — `rails-i18n` is already loaded.

**Version verification:**
```bash
$ grep "rails-i18n" Gemfile.lock
    devise-i18n (1.16.0)
      rails-i18n
    rails-i18n (8.1.0)
  rails-i18n (~> 8.0)
```
Confirmed: rails-i18n 8.1.0 is installed and bundled. [VERIFIED: 2026-05-01 against `/home/y-matsuda/project/bookmarks/Gemfile.lock`]

## Hardcoded Literal Inventory (Chrome Layer Only)

This is the **complete** inventory of chrome-layer hardcoded literals. Verified by `grep -rln '[ぁ-んァ-ヶー一-龠]' app/views/layouts/ app/views/common/ app/helpers/ app/controllers/` → only 4 files; of those, `bookmarks_controller.rb` contains only Japanese **comments**, which are not translation targets.

### app/views/layouts/application.html.erb [VERIFIED]

| Line | Literal | Type | Phase 16 Action | Proposed Key |
|------|---------|------|-----------------|--------------|
| 4 | `<title>Bookmarks</title>` | Brand | **KEEP UNTRANSLATED** (native brand) | — |
| 19 | `alt="Bookmarks"` | Brand alt | **KEEP UNTRANSLATED** (native brand, redundant with logo) | — |
| 20 | `link_to 'Bookmarks', root_path` | Brand | **KEEP UNTRANSLATED** (native brand) | — |
| 23 | `aria-label="メニュー"` | ARIA | **TRANSLATE** | `nav.menu_aria` (top-level shared, parallels `flash.*`) |
| 35 | `link_to 'Home', root_path` | Nav | **TRANSLATE** (also appears `_menu.html.erb:35`) | `nav.home` |
| 36 | `link_to '設定', preferences_path` | Nav | **TRANSLATE** (shared with `_menu.html.erb:42`) | `nav.preferences` |
| 37 | `link_to 'ブックマーク', bookmarks_path` | Nav | **TRANSLATE** (shared with `_menu.html.erb:43`) | `nav.bookmarks` |
| 38 | `link_to 'タスク', todos_path` | Nav | **TRANSLATE** (shared with `_menu.html.erb:44`) | `nav.todos` |
| 39 | `link_to 'カレンダー', calendars_path` | Nav | **TRANSLATE** (shared with `_menu.html.erb:45`) | `nav.calendars` |
| 40 | `link_to 'フィード', feeds_path` | Nav | **TRANSLATE** (shared with `_menu.html.erb:46`) | `nav.feeds` |
| 41 | `link_to 'ログアウト', destroy_user_session_path` | Nav | **TRANSLATE** (shared with `_menu.html.erb:47`) | `nav.sign_out` |

### app/views/common/_menu.html.erb [VERIFIED]

| Line | Literal | Type | Phase 16 Action | Proposed Key |
|------|---------|------|-----------------|--------------|
| 35 | `link_to 'Home', root_path` | Nav | **TRANSLATE** | `nav.home` (shared) |
| 37 | `link_to 'Note', root_path(tab: 'notes')` | Nav | **TRANSLATE** (English-as-native; both locales likely render "Note") | `nav.note` (top-level) |
| 42 | `link_to '設定', preferences_path` | Nav | **TRANSLATE** | `nav.preferences` (shared) |
| 43 | `link_to 'ブックマーク', bookmarks_path` | Nav | **TRANSLATE** | `nav.bookmarks` (shared) |
| 44 | `link_to 'タスク', todos_path` | Nav | **TRANSLATE** | `nav.todos` (shared) |
| 45 | `link_to 'カレンダー', calendars_path` | Nav | **TRANSLATE** | `nav.calendars` (shared) |
| 46 | `link_to 'フィード', feeds_path` | Nav | **TRANSLATE** | `nav.feeds` (shared) |
| 47 | `link_to 'ログアウト', destroy_user_session_path` | Nav | **TRANSLATE** | `nav.sign_out` (shared) |

### app/controllers/notes_controller.rb [VERIFIED]

| Line | Literal | Type | Phase 16 Action | Proposed Key |
|------|---------|------|-----------------|--------------|
| 8 | `'エラーが発生しました'` (fallback) | Flash | **TRANSLATE** per D-03 | `flash.errors.generic` |

### app/helpers/* [VERIFIED]

- `application_helper.rb`: empty module — no chrome strings.
- `welcome_helper.rb`: `favorite_theme`, `drawer_ui?`, `font_size_class` — no user-visible strings.
- `calendars_helper.rb`: feature-surface, **out of scope (Phase 17)**.

### Other controllers [VERIFIED]

- `bookmarks_controller.rb`: only Japanese **comments** (lines 8, 20, 35) — not translation targets.
- `users/two_factor_setup_controller.rb` (lines 15, 25): already `t('two_factor.enabled')` / `t('two_factor.disabled')` — already i18n'd. **Out of scope (Phase 18 will revisit Devise area).**
- `users/omniauth_callbacks_controller.rb` (line 17): already `I18n.t "devise.omniauth_callbacks.success"`. **Out of scope (Phase 18 — `devise-i18n` activation).**
- All other controllers: no flash/notice/alert calls with hardcoded strings.

### Phase 17 boundary verification (informational, NOT in Phase 16 scope)

These hardcoded strings live in feature `_form.html.erb` partials and **stay hardcoded after Phase 16**:

```
app/views/welcome/_note_gadget.html.erb:6:    <%= f.submit '保存' %>
app/views/todos/_form.html.erb:8:          <%= f.submit '登録', ... %>
app/views/todos/_form.html.erb:10:         <%= f.submit '更新', ... %>
app/views/{bookmarks,calendars,feeds}/_form.html.erb: <%= f.submit %>  (uses Rails default — already locale-aware via helpers.submit.*)
app/views/{bookmarks,feeds,todos,calendars}/...: '削除' literals + t('messages.confirm_delete', ...)
```

**Recommendation: defer to Phase 17.** Bias is conservative per CONTEXT.md. The `'削除'` link literal appears in 4 feature views and is a clear Phase 17 candidate (lives next to feature-specific delete confirms). The `f.submit '保存'/'登録'/'更新'` strings are feature-specific (note gadget body, todo create/update) and not "shared chrome."

**Total chrome-layer translatable items in Phase 16:** 9 distinct keys (`flash.errors.generic` + `nav.menu_aria` + `nav.{home, note, preferences, bookmarks, todos, calendars, feeds, sign_out}`).

## Architecture Patterns

### System Architecture Diagram

```
┌──────────────────────────────────────────────────────────────────┐
│                        HTTP request                               │
│             (Accept-Language, session cookie)                     │
└──────────────────────────────┬───────────────────────────────────┘
                               ▼
┌──────────────────────────────────────────────────────────────────┐
│ ApplicationController                                             │
│   include Localization (Phase 14)                                 │
│   around_action :set_locale  → I18n.with_locale(resolved)         │
│      ↓                                                            │
│   Resolved locale = saved Preference#locale → Accept-Language     │
│                     → :ja default                                 │
└──────────────────────────────┬───────────────────────────────────┘
                               ▼
┌──────────────────────────────────────────────────────────────────┐
│ Controller action                                                 │
│   - sets flash via t('flash.errors.generic') etc.   (Phase 16)    │
│   - validation errors via @model.errors.full_messages             │
│       └→ rails-i18n gem provides errors.messages.* defaults       │
│           in :ja and :en                                          │
└──────────────────────────────┬───────────────────────────────────┘
                               ▼
┌──────────────────────────────────────────────────────────────────┐
│ View rendering                                                    │
│   layouts/application.html.erb                                    │
│     <html lang="<%= I18n.locale %>">       (Phase 14)             │
│     <title>Bookmarks</title>               (untranslated brand)   │
│     aria-label="<%= t('nav.menu_aria') %>" (Phase 16)             │
│     drawer nav: t('nav.home'), t('nav.preferences'), ...          │
│   common/_menu.html.erb (simple theme)                            │
│     ul.navigation: t('nav.home'), t('nav.note'), ...              │
└──────────────────────────────┬───────────────────────────────────┘
                               ▼
                       Localized HTML
```

### Recommended Project Structure (no new files in app/)

```
config/locales/
├── ja.yml                # ADD nav.*, flash.* sections
└── en.yml                # ADD nav.*, flash.* sections (mirror ja keys exactly)

app/views/layouts/
└── application.html.erb  # MODIFY: replace 7 hardcoded strings with t() calls

app/views/common/
└── _menu.html.erb        # MODIFY: replace 7 hardcoded strings with t() calls

app/controllers/
└── notes_controller.rb   # MODIFY: line 8 fallback → t('flash.errors.generic')

test/
├── controllers/
│   ├── application_controller_test.rb  # ADD tests for chrome strings in ja & en
│   └── notes_controller_test.rb        # ADD test that en alert uses translated string
└── i18n/
    └── locales_parity_test.rb  # NEW: ja/en key parity test (recommended location)
```

### Pattern 1: Top-Level Absolute Keys for Cross-Partial Strings (D-01 + recommended for nav)

**What:** Strings used in 2+ unrelated locations live under a top-level namespace and are referenced via absolute keys.
**When to use:** When a string is shared across templates that have no parent/child relationship (e.g., layout drawer + simple-theme menu).
**Example:**
```yaml
# config/locales/ja.yml
ja:
  nav:
    home: ホーム
    preferences: 設定
    bookmarks: ブックマーク
    todos: タスク
    calendars: カレンダー
    feeds: フィード
    note: Note          # native English brand label, kept identical in en (D-06 spirit)
    sign_out: ログアウト
    menu_aria: メニュー
  flash:
    errors:
      generic: エラーが発生しました
```
```erb
<%# app/views/layouts/application.html.erb %>
<button class="hamburger-btn" aria-label="<%= t('nav.menu_aria') %>"></button>
<%= link_to t('nav.home'), root_path %>
```
[CITED: guides.rubyonrails.org/i18n.html#looking-up-translations]

### Pattern 2: Lazy Lookup Path-Match Discipline (D-05 carry-forward)

**What:** `t('.foo')` inside `app/views/X/Y.html.erb` resolves to `X.Y.foo`. Yml hierarchy must match the view path exactly.
**When to use:** When a string is single-use and partial-anchored.
**Phase 16 application:** **Not used.** All Phase 16 strings are either (a) shared (use absolute key per Pattern 1) or (b) single-use ARIA in `application.html.erb` — for which top-level `nav.menu_aria` is simpler than introducing a `layouts.application.*` subtree for one key.

### Pattern 3: rails-i18n Default Validation Messages (D-04)

**What:** `rails-i18n` gem ships YAMLs at `gems/rails-i18n-8.1.0/rails/locale/{ja,en}.yml` containing `errors.messages.*` (e.g., `blank`, `taken`, `inclusion`) and `activerecord.errors.messages.*`. When `I18n.available_locales = %i[ja en]` and the gem is bundled, both files load automatically — **no explicit `I18n.load_path` configuration needed.**
**Verification:**
```ruby
# Smoke test (manual or in tests)
I18n.with_locale(:ja) { I18n.t('errors.messages.blank') } # => "を入力してください"
I18n.with_locale(:en) { I18n.t('errors.messages.blank') } # => "can't be blank"
```
**Override risk:** Search `config/locales/ja.yml` and `en.yml` for any inadvertent `errors.messages.*` or `activerecord.errors.messages.*` blocks → **none present** [VERIFIED: `grep -n 'errors:' config/locales/*.yml` returns no matches]. Safe to activate.
[CITED: github.com/svenfuchs/rails-i18n#installation]

### Anti-Patterns to Avoid

- **Lazy lookup with mismatched path** — Phase 15 burned a fix-up plan on this. If a string lives in `app/views/X/Y.html.erb`, the yml key must be `X.Y.foo`, NOT `X.foo`. Phase 16 sidesteps this by using absolute keys for all 9 keys.
- **Translating `<title>Bookmarks</title>` or the logo `alt`** — the brand name is product identity, not chrome. Parallels Phase 15 D-02 native-label rule.
- **Per-controller flash keys** (`flash.notes.errors.generic`) — overkill for current flash volume; D-03 mandates one shared key.
- **Hand-rolling `errors.messages.blank` overrides** — rails-i18n provides them. Don't reinvent.
- **Adding `errors.messages.*` to project yml** — would shadow rails-i18n defaults silently.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Validation message localization | Custom `errors.messages` block in `ja.yml` | `rails-i18n` gem (already bundled) | Gem ships canonical translations for ~80 locales; reinventing risks subtle wording drift across rails versions. |
| Locale fallback chain | Custom fallback logic | Rails built-in `I18n.fallbacks` | Already handled in Phase 14 via `available_locales` + `enforce_available_locales`. No fallback config needed for ja/en — both are first-class. |
| Translation key linting | Custom rake task | (deferred — `i18n-tasks` gem when scale demands) | At ~20 keys, a 30-line minitest parity test beats a gem dependency. Revisit at Phase 18+. |
| Pluralization for navigation labels | Custom `t()` wrapper | Rails `:count` interpolation if needed | Phase 16 has zero pluralization needs (nav labels are bare nouns). |
| Accept-Language parsing | More parser code | Phase 14's existing `Localization` concern | Already done. |

**Key insight:** Phase 16 is almost entirely a **string-substitution exercise**. The hardest engineering decisions (locale resolution, whitelist safety, thread-local handling) were solved in Phase 14. The remaining risk is **mechanical** (typo'd yml keys, missed call sites, lazy/absolute mismatch) — managed by the parity test + integration assertions.

## Common Pitfalls

### Pitfall 1: Lazy-lookup template-path mismatch (Phase 15 carry-forward)

**What goes wrong:** Engineer writes `t('.title')` in `app/views/X/Y.html.erb` and adds key under `preferences.title:` in yml — lookup fails (resolves to `X.Y.title`).
**Why it happens:** Lazy lookup uses the full view path, not "the view's logical name."
**How to avoid:** Phase 16 uses **absolute keys for all 9 strings** — eliminates the class. If a future task adds a partial-anchored key, mirror the path exactly. Verify with the parity test.
**Warning signs:** Browser shows `translation missing: ja.X.Y.title` text rendered as-is.

### Pitfall 2: Broken intermediate state — view references key before yml has it

**What goes wrong:** Wave 2 substitutes `link_to t('nav.home'), root_path` before Wave 1 commits `nav.home:` to yml → app shows `translation missing: ja.nav.home` literally.
**Why it happens:** Out-of-order task execution or partial test runs. In dev mode `I18n.exception_handler` defaults to rendering the missing-translation string into HTML rather than raising.
**How to avoid:** **Wave order is yml-first, views-second, controller-third, tests-fourth.** Each wave commits to a clean intermediate state where neither half-translated keys nor orphan view references exist.
**Warning signs:** `translation missing` strings in rendered HTML or test output.

### Pitfall 3: rails-i18n silently overridden by app-side keys

**What goes wrong:** App's `ja.yml` defines `errors.messages.blank: '空欄不可'` → rails-i18n's nicer default is shadowed forever.
**Why it happens:** I18n `load_path` order: rails-i18n loads first, app `config/locales/*.yml` loads later and wins on duplicate keys.
**How to avoid:** Inventoried — Phase 16 yml additions live under `nav.*` and `flash.*` only. **Do not add `errors.messages.*` or `activerecord.errors.messages.*` to project yml.**
**Warning signs:** Validation messages don't match the rails-i18n canonical wording.

### Pitfall 4: Cucumber preference-state leakage masks a real Phase 16 regression

**What goes wrong:** A Cucumber scenario fails with "Unable to find link 'Home'" because a prior scenario left `theme = 'simple'` and the drawer rendered the simple-theme menu instead of the modern drawer (different DOM).
**Why it happens:** Documented in CLAUDE.md — scenarios share DB state without per-scenario truncation.
**How to avoid:** **Verify Phase 16 with Minitest integration tests, not new Cucumber scenarios.** Re-run policy: `dad:test` failure on first run → re-run; consistent failure across two runs → real regression. Do not mark phase complete on a single passing run if test was previously red.
**Warning signs:** First-run dad:test failures that disappear on retry — these are flakes; consistent failures are real.

### Pitfall 5: `notes_controller.rb` fallback evaluated at request time, not boot time

**What goes wrong:** `t('flash.errors.generic')` is evaluated inside the `redirect_to` call, so `I18n.locale` is whatever the around_action set for *this* request. Safe — but the planner must not stash the value in a constant (`MESSAGE = t(...)` at class load) which would freeze it to `:ja`.
**How to avoid:** Always inline `t()` at the call site, never at constant definition.
**Warning signs:** All users see `'エラーが発生しました'` regardless of locale.

## Runtime State Inventory

(Phase 16 is a code-only translation phase — no rename / migration / runtime-state churn.)

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | None — verified by inventory; no data references key strings | None |
| Live service config | None — no external service uses chrome strings | None |
| OS-registered state | None | None |
| Secrets/env vars | None | None |
| Build artifacts | None — no compiled assets reference Japanese chrome strings (CSS/JS untouched in Phase 16) | None |

## Code Examples

Verified patterns from official sources and existing codebase.

### Adding to ja.yml / en.yml (top-level absolute keys)

```yaml
# config/locales/ja.yml — add to existing top-level keys
ja:
  # ... existing activerecord, messages, two_factor, preferences ...

  nav:
    home: ホーム
    note: Note               # native brand label per native-label rule
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

```yaml
# config/locales/en.yml — mirror keys exactly (parity test enforces this)
en:
  nav:
    home: Home
    note: Note
    preferences: Preferences
    bookmarks: Bookmarks       # ⚠ collides with brand "Bookmarks"; acceptable per native-brand rule
    todos: Tasks
    calendars: Calendars
    feeds: Feeds
    sign_out: Sign out
    menu_aria: Menu

  flash:
    errors:
      generic: Something went wrong.
```
[CITED: guides.rubyonrails.org/i18n.html#adding-translations]

### Layout substitution

```erb
<%# app/views/layouts/application.html.erb (after Phase 16) %>
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

### Controller flash substitution (Phase 16 D-03)

```ruby
# app/controllers/notes_controller.rb (after Phase 16)
def create
  @note = Note.new(note_params)

  if @note.save
    redirect_to root_path(tab: 'notes')
  else
    redirect_to root_path(tab: 'notes'),
                alert: @note.errors.full_messages.to_sentence.presence || t('flash.errors.generic')
  end
end
```

### Parity test (recommended implementation)

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

**Why a custom test, not `i18n-tasks`:** REQUIREMENTS.md `I18NTOOL-01` defers `i18n-tasks` to a future milestone. At ~20 keys total, a 25-line minitest is faster, has zero gem cost, and directly satisfies success criterion 4 of Phase 16.

### Integration test for chrome strings

```ruby
# test/controllers/application_controller_test.rb (extend existing file)
def test_chromeはja_localeでホームと設定を含む
  user.preference.update!(locale: 'ja')
  sign_in user
  get root_path
  assert_select 'a', text: 'ホーム'
  assert_select 'a', text: '設定'
  assert_select 'button[aria-label=?]', 'メニュー'
end

def test_chromeはen_localeでHomeとPreferencesを含む
  user.preference.update!(locale: 'en')
  sign_in user
  get root_path
  assert_select 'a', text: 'Home'
  assert_select 'a', text: 'Preferences'
  assert_select 'button[aria-label=?]', 'Menu'
end
```

Note: drawer button only renders when `drawer_ui? == true` (i.e., `theme != 'simple'`). The default fixture theme should be checked; if simple, the test must set theme to `'modern'` or `'classic'` first to exercise the drawer assertion. The simple-theme menu has different DOM (`ul.navigation`) — add a parallel assertion for that path.

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Hardcoded literals scattered in views | `t('namespace.key')` with yml catalog | (already standard since Rails 2) | Phase 16 finally adopts this for chrome layer. |
| Per-controller flash keys (`controller_name.action_name.success`) | Top-level `flash.*` shared namespace | Phase 16 D-01 | DRY when flash count is small (~3 keys). Re-evaluate if flash count exceeds ~10. |
| Manual translation of `errors.messages.*` | `rails-i18n` gem | (community standard since 2010) | Phase 16 D-04 activates. |

**Deprecated/outdated:**
- `before_action :set_locale` (per-action) — superseded by `around_action` in Phase 14 (Puma thread-local pitfall). Phase 16 should not regress this.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | rails-i18n loads its `:ja` and `:en` yml automatically when `available_locales = %i[ja en]` and the gem is bundled — no `I18n.load_path << ...` needed | "rails-i18n Default Validation Messages" | LOW — verifiable with a 1-line `rails runner 'puts I18n.t("errors.messages.blank")'` smoke test. If wrong, planner adds a 1-line `config.i18n.load_path` entry. [ASSUMED — based on rails-i18n README; not verified in this repo's boot] |
| A2 | The brand "Bookmarks" stays untranslated in English locale; the en `nav.bookmarks: Bookmarks` collision is acceptable | "Code Examples" | LOW — wording confirmation falls to user/planner. If wrong, en `nav.bookmarks` could be e.g., "My bookmarks" to disambiguate. [ASSUMED] |
| A3 | The "Note" link in `_menu.html.erb:37` stays as "Note" in both locales (English-as-native brand), per Phase 15 D-02 native-label rule extension | Hardcoded Literal Inventory | LOW — wording-only. If user prefers `nav.note: ノート / Note`, swap one yml line. [ASSUMED] |
| A4 | Default fixture user preference has `theme != 'simple'` so the drawer renders by default | Code Examples → Integration test | LOW — verifiable via `cat test/fixtures/preferences.yml`; if wrong, test must set theme explicitly. The Cucumber flake doc in CLAUDE.md actually suggests fixture theme is **non-simple** (the flake is when scenarios pollute it to simple). [ASSUMED] |

## Open Questions

1. **Should `Note` and `Bookmarks` differ between ja and en?**
   - What we know: Phase 15 set the native-label rule for language-identity strings (`日本語`, `English`, `自動`). "Note" and "Bookmarks" are product/feature names with English origin.
   - What's unclear: Whether the user wants `nav.note: ノート` in ja, or keeps `Note` in both locales.
   - Recommendation: Keep "Note" identical in both (matches Phase 15 D-02 spirit and current Modern theme menu). User can override at plan-review time. **Bookmarks** brand and `nav.bookmarks` are technically distinct concepts (one is the product, one is the nav label) — keep both as "Bookmarks" in en for simplicity.

2. **Wave 0: does the project already have a `test/i18n/` directory or test load-path?**
   - What we know: `test/integration/` is an empty `.keep` (per Phase 14 CONTEXT). `test/controllers/` is the canonical home for IntegrationTest subclasses.
   - What's unclear: Whether a parity test file should live in `test/i18n/locales_parity_test.rb` (new dir) or `test/models/i18n_parity_test.rb` (existing dir, semantic mismatch).
   - Recommendation: New directory `test/i18n/` — Rails picks up any `*_test.rb` under `test/` automatically. Document in 16-VALIDATION.md as a Wave 0 task.

3. **Should the `Bookmarks` `<title>` be moved to a `content_for(:title)` mechanism in Phase 16 prep, even without translating it?**
   - What we know: Per-page titles are not in TRN-01 wording. Current title is static `Bookmarks` on every page.
   - What's unclear: Whether per-page titles will arrive in Phase 17/18 and whether plumbing for `content_for(:title)` should land now.
   - Recommendation: **No** — keep `<title>Bookmarks</title>` static in Phase 16. Out of scope per CONTEXT.md "page title strategy" deferred section. Bias is conservative; introducing the plumbing without a consumer is YAGNI.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| Ruby on Rails | All Phase 16 work | ✓ | 8.1 (`config.load_defaults 8.1`) | — |
| `rails-i18n` gem | D-04 validation defaults | ✓ | 8.1.0 [VERIFIED: Gemfile.lock] | — |
| `devise-i18n` gem | (NOT used in P16) | ✓ | 1.16.0 | — |
| Minitest | Test framework | ✓ | bundled with Rails | — |
| Cucumber + Chrome (rake dad:test) | Phase verification gate per CLAUDE.md | ✓ (per project setup) | per Gemfile | re-run flake policy |
| YAML / Psych | Parity test loads yml | ✓ | bundled with Ruby 3.4 | — |

**Missing dependencies with no fallback:** None.
**Missing dependencies with fallback:** None.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | Minitest 5.x with `ActionDispatch::IntegrationTest` (carry-over from Phases 14/15) |
| Config file | `test/test_helper.rb` |
| Quick run command | `bin/rails test test/i18n/locales_parity_test.rb test/controllers/application_controller_test.rb test/controllers/notes_controller_test.rb` |
| Full suite command | `bin/rails test` |
| Phase-gate suites (per CLAUDE.md) | `yarn run lint && bin/rails test && bundle exec rake dad:test` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|--------------|
| TRN-01 | Layout drawer + simple-theme menu render `t('nav.*')` strings in active locale | integration | `bin/rails test test/controllers/application_controller_test.rb` | ✅ exists (extend) |
| TRN-01 | ARIA `menu_aria` translates per locale | integration | `bin/rails test test/controllers/application_controller_test.rb` | ✅ exists (extend) |
| TRN-04 | `notes_controller.rb` fallback flash uses `t('flash.errors.generic')` and produces locale-correct text on validation failure | integration | `bin/rails test test/controllers/notes_controller_test.rb` | ✅ exists (extend) |
| TRN-04 | rails-i18n `errors.messages.blank` resolves in both `:ja` and `:en` (smoke test that gem is loaded) | unit | `bin/rails test test/i18n/rails_i18n_smoke_test.rb` | ❌ Wave 0 |
| Phase-16 SC4 | ja.yml and en.yml have identical key sets | unit | `bin/rails test test/i18n/locales_parity_test.rb` | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** `bin/rails test test/i18n/ test/controllers/application_controller_test.rb test/controllers/notes_controller_test.rb` (~5 sec)
- **Per wave merge:** `bin/rails test` full suite (~15 sec)
- **Phase gate:** `yarn run lint && bin/rails test && bundle exec rake dad:test` per CLAUDE.md.
  - Cucumber flake handling: re-run `dad:test` once on failure; treat consistent two-run failure as real regression.

### Wave 0 Gaps
- [ ] `test/i18n/locales_parity_test.rb` — covers Phase-16 SC4 (ja/en key parity)
- [ ] `test/i18n/rails_i18n_smoke_test.rb` — covers TRN-04 rails-i18n activation (~5 line test asserting `I18n.with_locale(:en) { I18n.t('errors.messages.blank') } == "can't be blank"` and ja equivalent)
- [ ] (No new framework install needed.)

### Cucumber posture
**No new Cucumber scenarios for Phase 16.** Per CLAUDE.md flakiness, Minitest integration tests are the green-bar gate for chrome translation. Existing Cucumber scenarios continue to pass (re-run policy applies); they implicitly exercise translated drawer/nav strings since the test runner uses the default locale.

## Security Domain

> security_enforcement is not explicitly enabled in `.planning/config.json`. Phase 16 is a translation phase with **no auth, session, input-validation, or crypto changes** beyond what Phase 14 already secured. ASVS impact is minimal:

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | (Phase 18 territory; devise-i18n) |
| V3 Session Management | no | (Phase 14 already secured `I18n.locale` thread-local handling) |
| V4 Access Control | no | — |
| V5 Input Validation | indirect | rails-i18n provides validation **messages**, not validation logic. No new input surface. |
| V6 Cryptography | no | — |

### Known Threat Patterns for Rails i18n

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Cross-locale flash injection (untrusted content interpolated into translation) | Injection / Tampering | D-02 confines `name:` interpolation to `@record.title` (user-content shown back to its owner — same trust boundary as `messages.confirm_delete` already in use). No translated string concatenates request params. |
| Translation-missing leak revealing key paths | Information Disclosure | rails-i18n + parity test eliminate. In production `config.i18n.raise_on_missing_translations` defaults are environment-specific; Phase 16 doesn't change this. |
| Unsupported locale forced via header | Spoofing | Phase 14 whitelist (`Preference::SUPPORTED_LOCALES`) — already mitigated. |

**Conclusion:** No new threat surface introduced by Phase 16.

## Cross-Cutting Risk (Phase 14/15 regression check)

| Risk | Likelihood | Detection |
|------|------------|-----------|
| Translating drawer nav breaks drawer JS interaction (event handlers selector by class, not text) | LOW | Drawer JS in Phase 8 (v1.2) selects by `.hamburger-btn`, `.drawer`, `.drawer-overlay` — not by link text. Existing Cucumber scenarios that click the hamburger continue to pass. |
| `aria-label` change breaks accessibility test | NONE | No existing tests assert the literal `'メニュー'` string against ARIA. Planner should add one positive assertion in each locale (covered above). |
| `<html lang>` changed by side effect | NONE | Phase 14's `<html lang="<%= I18n.locale %>">` is untouched in Phase 16. |
| Language preference page (`/preferences`) UX regression | NONE | Phase 16 does not modify `app/views/preferences/index.html.erb` or `PreferencesController`. |
| Validation message override masking rails-i18n defaults | LOW | `grep` for `errors:` in `config/locales/*.yml` returned no matches. Plan must not introduce `errors.messages.*` keys. |
| Cucumber preference-state leak attributed to Phase 16 instead of pre-existing flake | MEDIUM | Re-run policy from CLAUDE.md. Planner should make the verification explicit. |

## Wave Sequencing (recommended dependency graph)

```
Wave 1: catalog
  Plan 16-01: ja.yml + en.yml additions (nav.*, flash.*)
              + parity test (test/i18n/locales_parity_test.rb)
              + rails-i18n smoke test (test/i18n/rails_i18n_smoke_test.rb)
              ─ ends in green parity + green smoke test
              ─ no view/controller changes — app behavior unchanged

Wave 2: substitution (parallel-safe — no shared files)
  Plan 16-02a: app/views/layouts/application.html.erb — 8 substitutions
  Plan 16-02b: app/views/common/_menu.html.erb — 7 substitutions
  Plan 16-02c: app/controllers/notes_controller.rb — 1 substitution
              ─ each touches a different file, no merge conflict
              ─ depends on Wave 1 yml keys existing

Wave 3: integration tests
  Plan 16-03: extend test/controllers/application_controller_test.rb (chrome ja+en)
              extend test/controllers/notes_controller_test.rb (flash.errors.generic ja+en)
              ─ depends on Waves 1+2
              ─ green = TRN-01 + TRN-04 evidence
```

**Why yml-first:** prevents the broken-intermediate-state pitfall #2. After Wave 1 commits, the yml is authoritative and views can reference any key without `translation missing` rendering.

**Why parity test in Wave 1:** if Wave 2 substitution introduces a typo'd key, the parity test catches it at the next test run (since the typo appears in only one file's view but the existing yml entry is for a different key — actually, wait: parity test compares yml-to-yml only; a typo in a view shows up in integration tests in Wave 3). The parity test specifically catches the case where Wave 1 forgets to add a key to one of the two yml files.

**Wave 2 parallelism:** All three plans can run in parallel because they touch different files. The planner can choose to merge them into a single plan if simpler.

## Sources

### Primary (HIGH confidence)
- `app/views/layouts/application.html.erb` (read 2026-05-01) — chrome inventory ground truth
- `app/views/common/_menu.html.erb` (read 2026-05-01) — simple-theme menu ground truth
- `app/controllers/notes_controller.rb` (read 2026-05-01) — D-03 target
- `config/locales/ja.yml`, `config/locales/en.yml` (read 2026-05-01) — current key inventory
- `Gemfile.lock` (verified 2026-05-01) — `rails-i18n (8.1.0)`, `devise-i18n (1.16.0)`
- `config/application.rb` (read 2026-05-01) — `available_locales = %i[ja en]`
- `.planning/phases/14-locale-infrastructure/14-CONTEXT.md` — D-01..D-04 + Localization concern contract
- `.planning/phases/15-language-preference/15-CONTEXT.md` — D-08 lazy-lookup pitfall, native-label rule
- `.planning/phases/16-core-shell-and-shared-messages-translation/16-CONTEXT.md` — D-01..D-06 locked decisions
- `CLAUDE.md` — verification policy + Cucumber flake policy
- Rails Guides: I18n API and Lookup Rules [CITED: guides.rubyonrails.org/i18n.html]
- rails-i18n README [CITED: github.com/svenfuchs/rails-i18n]

### Secondary (MEDIUM confidence)
- Cross-grepped `app/controllers/` for hardcoded literals — bookmarks_controller.rb confirmed comments-only via line inspection.
- Cross-grepped `app/views/` for `f.submit '保存'` etc. — confirmed feature-only, Phase 17 boundary.

### Tertiary (LOW confidence)
- A1 (auto-load behavior of rails-i18n with `available_locales` whitelist) — based on README, not verified in this repo's boot. Planner should add the smoke test as Wave 0 to verify.

## Metadata

**Confidence breakdown:**
- Hardcode inventory: HIGH — exhaustive grep over chrome dirs
- Standard stack (rails-i18n): HIGH — version verified in Gemfile.lock
- Architecture (key namespace): HIGH — based on Phase 15 lessons + call-site count evidence
- Pitfalls: HIGH — 3 of 5 are direct carry-forward from Phases 14/15
- rails-i18n auto-load behavior: MEDIUM — assumption A1, planner verifies via smoke test
- Phase 16/17 boundary: HIGH — verified by feature-form grep

**Research date:** 2026-05-01
**Valid until:** 2026-06-01 (stable Rails 8.1 / rails-i18n 8.1 ecosystem; phase work expected to complete within days)

## RESEARCH COMPLETE
