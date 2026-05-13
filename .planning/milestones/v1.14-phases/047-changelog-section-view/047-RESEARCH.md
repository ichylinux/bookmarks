# Phase 47: Changelog Section View - Research

**Researched:** 2026-05-10
**Domain:** Rails ERB view, SCSS, I18n, Minitest assert_select
**Confidence:** HIGH

## Summary

Phase 47 adds a `<section class="landing-changelog">` below the existing `.landing-value-grid` in `app/views/landing/show.html.erb`. The data layer (helper, locale YAML) was completed in Phase 46 and is fully verified in place. All CSS goes into the existing `landing.css.scss` before the final `@media` block. No controller changes are needed.

The scope is narrow and well-constrained by CONTEXT.md. The only implementation work is: (1) appending the ERB section to the view, (2) adding ~40 lines of CSS above the media query block, and (3) extending `landing_controller_test.rb` with two assertions covering the new section.

**Primary recommendation:** Append the ERB section after line 26 (`</main>` closes after `</section>` on line 25), insert new CSS rules on line 77 (just before `@media (max-width: 767px)`), and add two new test methods to `landing_controller_test.rb`.

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- Section placement: `<section class="landing-changelog">` after closing `</section>` of `.landing-value-grid` in `app/views/landing/show.html.erb`. No controller changes.
- Card layout: single-column stacked list, full content width.
- Card visual style: `.changelog-card` (new class, not reusing `.landing-value-card`). Same border `1px solid #d6dbe5`, border-radius `10px`, padding `18px`, white background, vertical stack gap `10px`.
- Section heading: `<h2 class="changelog-heading">` using `t('landing.changelog.heading')`. Style: ~16px, bold, color `#4f6b95`.
- Tag badge: `<span class="changelog-tag changelog-tag--{key}">` with `t("landing.changelog.tags.#{entry[:tag]}")`. CSS: pill, `font-size: 11px`, `padding: 2px 8px`, `border-radius: 12px`, `font-weight: 700`.
- Tag color map (bg / text): `ux` → `#e8f0fe`/`#2f6feb`; `fix` → `#fff3e0`/`#e65c00`; `performance` → `#e6f4ea`/`#1e7e34`; `new` → `#f3e8fd`/`#7b2db0`.
- Date: raw YYYY-MM-DD string in `<time class="changelog-date" datetime="...">`. CSS: `font-size: 12px`, `color: #6b7a99`.
- Card HTML structure: `<article class="changelog-card">` containing `.changelog-card-meta` (time + span), `h3.changelog-headline`, `p.changelog-description`.
- All CSS in `app/assets/stylesheets/landing.css.scss` (no new file).
- New classes: `.landing-changelog`, `.changelog-heading`, `.changelog-card`, `.changelog-card-meta`, `.changelog-date`, `.changelog-tag`, `.changelog-tag--ux`, `.changelog-tag--fix`, `.changelog-tag--performance`, `.changelog-tag--new`, `.changelog-headline`, `.changelog-description`.
- Mobile: no special overrides needed beyond existing `@media (max-width: 767px)` block.

### Claude's Discretion

None explicitly delegated.

### Deferred Ideas (OUT OF SCOPE)

None identified.
</user_constraints>

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Changelog data retrieval | Backend (ApplicationHelper) | — | `changelog_entries` reads from I18n YAML via helper; no controller involvement |
| Section rendering | Frontend Server (ERB/SSR) | — | Standard Rails server-side rendering; no JS |
| Styling | CDN / Static (SCSS compiled asset) | — | Pure CSS; no JS framework |
| Locale text | Backend I18n | — | `t()` resolved at render time server-side |

---

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Rails ERB | 7.2 | View templating | Project standard [VERIFIED: codebase] |
| SCSS (Sprockets) | existing | Stylesheet | Project uses `.css.scss` extension throughout [VERIFIED: codebase] |
| Rails I18n `t()` | built-in | Locale text | All landing view strings use `t('landing.*')` [VERIFIED: codebase] |
| ApplicationHelper | Phase 46 | `changelog_entries` data | Already implemented and tested [VERIFIED: codebase] |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Minitest assert_select | built-in | HTML structure assertions | Used in all controller tests [VERIFIED: codebase] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| t() full key | Lazy t('.key') | Lazy t() works only in views named to match locale key path; landing view uses full keys consistently — stay consistent |

---

## Architecture Patterns

### System Architecture Diagram

```
GET /landing
     |
     v
LandingController#show
     |
     v
app/views/landing/show.html.erb
     |
     +-- .landing-hero section (existing)
     |
     +-- .landing-value-grid section (existing, 3 cards)
     |
     +-- .landing-changelog section  <-- NEW
           |
           v
       changelog_entries (ApplicationHelper)
           |
           v
       I18n.t('landing.changelog.entries')  [ja.yml / en.yml]
           |
           v
       sorted descending, capped at 10
           |
           v
       .changelog-card articles (ERB each loop)

Styles: app/assets/stylesheets/landing.css.scss
        compiled by Sprockets at request time (dev) / precompiled (prod)
```

### Recommended Project Structure

No new files. Modifications only:

```
app/
├── views/landing/show.html.erb       # append landing-changelog section
└── assets/stylesheets/landing.css.scss  # add new classes before @media block

test/
└── controllers/landing_controller_test.rb  # add 2 new test methods
```

### Pattern 1: Full-key t() in landing view

**What:** All strings in `show.html.erb` use explicit full-key `t('landing.*')` calls, not lazy dot-notation `t('.key')`.
**When to use:** Always in this view — it is the established convention.

```erb
<%# Source: app/views/landing/show.html.erb (verified) %>
<p class="landing-eyebrow"><%= t('landing.hero.eyebrow') %></p>
<h2><%= t('landing.values.capture.title') %></h2>
```

New changelog section follows the same pattern:

```erb
<h2 class="changelog-heading"><%= t('landing.changelog.heading') %></h2>
<span class="changelog-tag changelog-tag--<%= entry[:tag] %>">
  <%= t("landing.changelog.tags.#{entry[:tag]}") %>
</span>
```

### Pattern 2: assert_select in landing controller tests

**What:** Tests make a GET request to `landing_path` then assert CSS selectors are present.
**When to use:** Verifying HTML structure from controller layer.

```ruby
# Source: test/controllers/landing_controller_test.rb (verified)
def test_未ログインでもlandingを表示できる
  get landing_path
  assert_response :success
  assert_select '.landing-page', count: 1
end
```

New tests for Phase 47 follow this exact pattern:

```ruby
def test_landingにchangelogセクションが表示される
  get landing_path
  assert_response :success
  assert_select 'section.landing-changelog', count: 1
  assert_select 'h2.changelog-heading', count: 1
  assert_select 'article.changelog-card'
end

def test_landingのchangelogカードにmetaとheadlineが含まれる
  get landing_path
  assert_response :success
  assert_select '.changelog-card .changelog-card-meta', minimum: 1
  assert_select '.changelog-card time.changelog-date', minimum: 1
  assert_select '.changelog-card h3.changelog-headline', minimum: 1
end
```

### Anti-Patterns to Avoid

- **Lazy t() notation (`t('.heading')`):** The view file name does not map to the `landing.changelog` key namespace cleanly via lazy lookup. Use explicit full key `t('landing.changelog.heading')`.
- **Reusing `.landing-value-card`:** CONTEXT.md explicitly prohibits this. Create `.changelog-card`.
- **Adding CSS inside the `@media` block:** New desktop-first rules must be inserted before line 78 (the `@media` opening). Mobile override for `.landing-changelog` is not required per CONTEXT.md.
- **Using `Date.parse` or `l()`:** The `entry[:date]` field is already a `YYYY-MM-DD` string; render it directly in the `<time>` element.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Changelog data retrieval | Custom query/file parser | `changelog_entries` (Phase 46, ApplicationHelper) | Already implemented, tested, sorted, capped |
| Locale text | Inline hardcoded strings | `t('landing.changelog.*')` | ja + en YAMLs fully populated (Phase 46) |

---

## Exact Insertion Points

### Q1: Where exactly does the new section go in `show.html.erb`?

**Current file structure (26 lines, VERIFIED):**

```
line 1:  <main class="landing-page">
line 2:    <section class="landing-hero">
...
line 10:   </section>        ← end of .landing-hero
line 11:   (blank)
line 12:   <section class="landing-value-grid">
...
line 25:   </section>        ← end of .landing-value-grid  ← INSERT AFTER THIS
line 26: </main>
```

The new `<section class="landing-changelog">` goes between line 25 and line 26. The `</main>` tag moves to close after the new section. [VERIFIED: codebase]

### Q2: Where exactly does the new CSS go in `landing.css.scss`?

**Current file structure (94 lines, VERIFIED):**

```
lines 1–77:   desktop rules (.landing-page through .landing-value-card p)
line 78:      @media (max-width: 767px) {   ← INSERT NEW RULES BEFORE THIS LINE
lines 78–94:  mobile overrides
```

New CSS classes (`.landing-changelog`, `.changelog-heading`, `.changelog-card`, etc.) are inserted at line 78, immediately before the `@media` block. [VERIFIED: codebase]

---

## Common Pitfalls

### Pitfall 1: Dynamic class interpolation with I18n key

**What goes wrong:** `changelog-tag--<%= entry[:tag] %>` renders an unexpected class if `entry[:tag]` contains characters not in the 4 defined keys (`ux`, `fix`, `performance`, `new`).
**Why it happens:** The YAML data is authored by humans; a typo produces an unstyled badge.
**How to avoid:** The `changelog_entries` helper returns data from I18n YAML which is verified by `ChangelogI18nTest`. Each entry's tag field is validated to be present. No additional guard needed in the view — the test suite catches bad data.
**Warning signs:** Badge renders but has no background color. [ASSUMED — no explicit guard in view was found; I18n tests cover field presence but not tag key membership]

### Pitfall 2: Section renders empty (no cards shown)

**What goes wrong:** `changelog_entries` returns `[]` if `landing.changelog.entries` key is missing or malformed in YAML.
**Why it happens:** The helper uses `default: []` to avoid raising on missing key.
**How to avoid:** `ChangelogI18nTest` (existing) verifies non-empty entries for both locales. The controller test should assert `article.changelog-card` is present (using `minimum: 1` not `count: 1`) to catch this in CI.
**Warning signs:** Section heading renders but no cards appear. [VERIFIED: application_helper_test.rb, changelog_i18n_test.rb]

### Pitfall 3: CSS rule order — specificity bleed

**What goes wrong:** `.landing-value-card h2` rule on line 69 might affect `h2.changelog-heading` if `.landing-changelog` is placed inside `.landing-value-grid` (wrong nesting).
**Why it happens:** The new section is a sibling of `.landing-value-grid`, not a child — if the ERB is accidentally indented inside the grid section, the existing grid h2 styles apply.
**How to avoid:** Ensure `<section class="landing-changelog">` is a sibling element (same indent level as `.landing-value-grid`), not nested inside it. [VERIFIED: show.html.erb structure]

---

## Code Examples

### Complete ERB section to append

```erb
<%# Source: CONTEXT.md (047-CONTEXT.md), locked decision %>
<section class="landing-changelog">
  <h2 class="changelog-heading"><%= t('landing.changelog.heading') %></h2>
  <% changelog_entries.each do |entry| %>
    <article class="changelog-card">
      <div class="changelog-card-meta">
        <time class="changelog-date" datetime="<%= entry[:date] %>"><%= entry[:date] %></time>
        <span class="changelog-tag changelog-tag--<%= entry[:tag] %>">
          <%= t("landing.changelog.tags.#{entry[:tag]}") %>
        </span>
      </div>
      <h3 class="changelog-headline"><%= entry[:headline] %></h3>
      <p class="changelog-description"><%= entry[:description] %></p>
    </article>
  <% end %>
</section>
```

### Complete CSS block to insert before `@media` line

```scss
/* Insert at line 78, immediately before @media (max-width: 767px) */
/* Source: CONTEXT.md (047-CONTEXT.md), locked decision */

.landing-changelog {
  margin-top: 18px;
}

.changelog-heading {
  color: #4f6b95;
  font-size: 16px;
  font-weight: 700;
  margin: 0 0 12px;
}

.changelog-card {
  background: #fff;
  border: 1px solid #d6dbe5;
  border-radius: 10px;
  display: flex;
  flex-direction: column;
  gap: 6px;
  margin-bottom: 10px;
  padding: 18px;
}

.changelog-card:last-child {
  margin-bottom: 0;
}

.changelog-card-meta {
  align-items: center;
  display: flex;
  gap: 8px;
}

.changelog-date {
  color: #6b7a99;
  font-size: 12px;
}

.changelog-tag {
  border-radius: 12px;
  font-size: 11px;
  font-weight: 700;
  padding: 2px 8px;
}

.changelog-tag--ux {
  background: #e8f0fe;
  color: #2f6feb;
}

.changelog-tag--fix {
  background: #fff3e0;
  color: #e65c00;
}

.changelog-tag--performance {
  background: #e6f4ea;
  color: #1e7e34;
}

.changelog-tag--new {
  background: #f3e8fd;
  color: #7b2db0;
}

.changelog-headline {
  font-size: 15px;
  font-weight: 600;
  margin: 0;
}

.changelog-description {
  color: #444;
  line-height: 1.55;
  margin: 0;
}
```

### New test methods for `landing_controller_test.rb`

```ruby
# Source: CONTEXT.md + existing test pattern in landing_controller_test.rb
def test_landingにchangelogセクションが表示される
  get landing_path
  assert_response :success
  assert_select 'section.landing-changelog', count: 1
  assert_select 'h2.changelog-heading', count: 1
  assert_select 'article.changelog-card', minimum: 1
end

def test_landingのchangelogカードにmetaとheadlineが含まれる
  get landing_path
  assert_response :success
  assert_select '.changelog-card .changelog-card-meta', minimum: 1
  assert_select '.changelog-card time.changelog-date', minimum: 1
  assert_select '.changelog-card h3.changelog-headline', minimum: 1
  assert_select '.changelog-card p.changelog-description', minimum: 1
end
```

---

## Existing Test Coverage (Phase 46 — already passing)

| Test file | What it covers | Relevance to Phase 47 |
|-----------|----------------|----------------------|
| `test/helpers/application_helper_test.rb` | `changelog_entries` sorting, capping, required keys | Helper called by new view — covered |
| `test/i18n/changelog_i18n_test.rb` | `landing.changelog.*` keys for ja + en | Locale keys used in new view — covered |
| `test/controllers/landing_controller_test.rb` | landing page response, CTAs, locale | Must be extended with changelog section assertions |

No Cucumber feature covers the landing page. The existing `.feature` files are:
- `01.ブックマーク.feature`
- `02.タスク.feature`
- `03.モダンテーマ.feature`
- `04.ノート.feature`

None reference landing, changelog, or 新着情報. No Cucumber work is needed for Phase 47. [VERIFIED: features/ directory listing]

---

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | Minitest (ActionDispatch::IntegrationTest) |
| Config file | `test/test_helper.rb` |
| Quick run command | `bin/rails test test/controllers/landing_controller_test.rb` |
| Full suite command | `yarn run lint && bin/rails test && bundle exec rake dad:test` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| VIEW-01 | `section.landing-changelog` present in HTML | integration | `bin/rails test test/controllers/landing_controller_test.rb` | Wave 0 — add methods |
| VIEW-02 | `h2.changelog-heading` present | integration | same | Wave 0 — add methods |
| VIEW-03 | `article.changelog-card` rendered (at least 1) | integration | same | Wave 0 — add methods |
| VIEW-04 | `.changelog-card-meta`, `time.changelog-date`, `h3.changelog-headline`, `p.changelog-description` present | integration | same | Wave 0 — add methods |

### Sampling Rate

- **Per task commit:** `bin/rails test test/controllers/landing_controller_test.rb`
- **Per wave merge:** `bin/rails test`
- **Phase gate:** `yarn run lint && bin/rails test && bundle exec rake dad:test`

### Wave 0 Gaps

- [ ] Two new test methods in `test/controllers/landing_controller_test.rb` — covers VIEW-01 through VIEW-04

*(No new test files needed — extending existing file.)*

---

## Security Domain

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V5 Input Validation | yes (limited) | `t()` escapes output by default; `entry[:headline]` and `entry[:description]` from I18n YAML are trusted developer-authored content, not user input |
| V4 Access Control | no | Landing page is intentionally public (no auth required) |
| V2 Authentication | no | No auth changes |
| V6 Cryptography | no | No secrets |

No security concerns: all rendered data originates from version-controlled YAML files, not from user input or database queries. ERB's `<%= %>` HTML-escapes by default. [VERIFIED: codebase patterns]

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Tag key values in locale YAML are always one of `ux`, `fix`, `performance`, `new` — no guard in view needed | Pitfall 1 | An unrecognized tag key would render without badge color; badge would be unstyled but not broken |

---

## Open Questions

None. All research questions answered with HIGH confidence from verified codebase inspection.

---

## Environment Availability

Step 2.6: SKIPPED (no external dependencies — pure ERB/SCSS/I18n changes, no CLI tools, services, or new packages required).

---

## Sources

### Primary (HIGH confidence)

- `app/views/landing/show.html.erb` (26 lines) — exact structure verified
- `app/assets/stylesheets/landing.css.scss` (94 lines) — exact structure, insertion point at line 77 verified
- `app/helpers/application_helper.rb` — `changelog_entries` method verified
- `config/locales/ja.yml` — `landing.changelog.*` keys verified (heading, tags, entries)
- `config/locales/en.yml` — `landing.changelog.*` keys verified (heading, tags, entries)
- `test/controllers/landing_controller_test.rb` — existing test methods and patterns verified
- `test/helpers/application_helper_test.rb` — Phase 46 helper tests verified
- `test/i18n/changelog_i18n_test.rb` — Phase 46 I18n tests verified
- `features/` directory listing — confirmed no landing/changelog Cucumber feature exists

### Secondary (MEDIUM confidence)

None needed — all findings from direct codebase inspection.

### Tertiary (LOW confidence)

None.

---

## Metadata

**Confidence breakdown:**

- Standard stack: HIGH — all libraries are existing project dependencies, verified in codebase
- Architecture: HIGH — insertion points confirmed by reading exact file contents
- Pitfalls: MEDIUM — pitfall 1 (tag key guard) is ASSUMED; pitfalls 2 and 3 are HIGH

**Research date:** 2026-05-10
**Valid until:** 2026-06-10 (30 days — stable Rails/SCSS domain, no fast-moving dependencies)
