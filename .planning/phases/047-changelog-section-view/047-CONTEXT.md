---
phase: 47
name: Changelog Section View
date: 2026-05-10
status: discussed
mode: autonomous (auto-answered)
---

# Phase 47 Context: Changelog Section View

## Domain

Render the "What's New" changelog section on `/landing` for all visitors (guest and signed-in alike). The section appears below the existing `.landing-value-grid` and displays curated changelog cards sourced from `changelog_entries` (Phase 46 helper).

## Decisions

### Section Placement

The `<section class="landing-changelog">` is rendered after the closing `</section>` of `.landing-value-grid` in `app/views/landing/show.html.erb`. No controller changes needed — `changelog_entries` is a helper callable directly from the view.

### Card Layout

Single-column stacked list. Each card occupies the full content width (same `max-width: 960px` container as the rest of the landing page). Description text is narrative and benefits from the full width. No grid needed.

### Card Visual Style

New CSS class `.changelog-card` extends the existing landing card baseline:
- Same border: `1px solid #d6dbe5`
- Same border-radius: `10px`
- Same padding: `18px`
- White background
- Vertical stack gap: `10px` (matching `.landing-value-grid` gap of `12px` approximately)

Do NOT reuse `.landing-value-card` directly — the changelog needs its own class for future flexibility. Pattern is the same, class is new.

### Section Heading

`<h2 class="changelog-heading">` renders `t('landing.changelog.heading')`.
- ja: 「新着情報」
- en: "What's New"
Typography: matches `.landing-eyebrow` style conceptually but rendered as h2 for semantics. Use a custom `.changelog-heading` class with modest sizing (~16px, bold, `#4f6b95` color — consistent with eyebrow treatment).

### Tag Badge

Inline colored pill rendered before the headline on each card.

```html
<span class="changelog-tag changelog-tag--<%= entry[:tag] %>">
  <%= t("landing.changelog.tags.#{entry[:tag]}") %>
</span>
```

CSS: small pill (`font-size: 11px`, `padding: 2px 8px`, `border-radius: 12px`, `font-weight: 700`).

Tag color map (background / text):
- `ux`          → `#e8f0fe` / `#2f6feb`  (blue — matches CTA primary)
- `fix`         → `#fff3e0` / `#e65c00`  (orange)
- `performance` → `#e6f4ea` / `#1e7e34`  (green)
- `new`         → `#f3e8fd` / `#7b2db0`  (purple)

### Date Display

Display the raw `YYYY-MM-DD` string from the entry hash. No Rails `l()` or `Date.parse` needed — the data is already a clean, readable ISO 8601 string. Rendered in a `<time>` element with `datetime` attribute for accessibility.

```html
<time class="changelog-date" datetime="<%= entry[:date] %>"><%= entry[:date] %></time>
```

CSS: `font-size: 12px`, `color: #6b7a99` (muted), rendered above the headline.

### Card HTML Structure (per entry)

```html
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
```

### Full Section HTML Structure

```html
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

### CSS File

All new styles added to `app/assets/stylesheets/landing.css.scss` (existing file). No new stylesheet needed.

New classes: `.landing-changelog`, `.changelog-heading`, `.changelog-card`, `.changelog-card-meta`, `.changelog-date`, `.changelog-tag`, `.changelog-tag--ux`, `.changelog-tag--fix`, `.changelog-tag--performance`, `.changelog-tag--new`, `.changelog-headline`, `.changelog-description`.

Mobile responsive: `.landing-changelog` inherits the existing `max-width: 960px` container; no special mobile overrides needed beyond the existing `@media (max-width: 767px)` block (cards are already single-column).

## Code Context

- **Landing view:** `app/views/landing/show.html.erb` — append changelog section after `.landing-value-grid`
- **Landing CSS:** `app/assets/stylesheets/landing.css.scss` — add new classes at end
- **ApplicationHelper:** `app/helpers/application_helper.rb` — `changelog_entries` method (Phase 46, ready)
- **Locale files:** `config/locales/ja.yml`, `config/locales/en.yml` — `landing.changelog.*` keys (Phase 46, ready)
- **LandingController:** `app/controllers/landing_controller.rb` — no changes needed

## Canonical Refs

- `app/views/landing/show.html.erb` — primary view file to modify
- `app/assets/stylesheets/landing.css.scss` — primary CSS file to modify
- `app/helpers/application_helper.rb` — `changelog_entries` helper (Phase 46)
- `config/locales/ja.yml`, `config/locales/en.yml` — `landing.changelog.*` locale data (Phase 46)
- `.planning/ROADMAP.md` — Phase 47 success criteria
- `.planning/phases/046-changelog-data-layer/046-CONTEXT.md` — prior phase decisions

## Deferred Ideas

None identified.
