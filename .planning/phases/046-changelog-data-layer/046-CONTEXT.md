---
phase: 46
name: Changelog Data Layer
date: 2026-05-10
status: discussed
mode: autonomous (auto-answered)
---

# Phase 46 Context: Changelog Data Layer

## Domain

Add bilingual changelog entries to `ja.yml` / `en.yml` under the existing `landing:` namespace and expose a helper method that returns entries sorted by date descending, capped at 10.

## Decisions

### YAML Structure

Entries live as a YAML array under `landing.changelog.entries`. Each entry is a hash with four keys:
- `date` — ISO 8601 string (`"2026-05-10"`)
- `headline` — Short localized title string
- `tag` — Tag key string (e.g., `"ux"`, `"fix"`, `"performance"`, `"new"`) — NOT the display label
- `description` — Longer localized description string

Rails i18n handles YAML arrays natively; `I18n.t('landing.changelog.entries')` returns `Array<Hash>` with symbolized keys.

### Tag Taxonomy

Four supported tags, defined as locale keys under `landing.changelog.tags`:
- `ux` → 「使いやすさ」 / "UX"
- `fix` → 「修正」 / "Fix"
- `performance` → 「パフォーマンス」 / "Performance"
- `new` → 「新機能」 / "New"

Tag entries in YAML use the key string (e.g., `tag: "ux"`). The view renders `t("landing.changelog.tags.#{entry[:tag]}")`.

### Section Heading

Key: `landing.changelog.heading`
- ja: `新着情報`
- en: `What's New`

### Helper Placement

Single method `changelog_entries` added to `ApplicationHelper`. No dedicated helper file — project does not have `LandingHelper` and one method doesn't warrant it.

```ruby
def changelog_entries
  entries = I18n.t('landing.changelog.entries', default: [])
  entries.sort_by { |e| e[:date] }.reverse.first(10)
end
```

### Entry Count

ROADMAP.md specifies cap at 10. Enforced in the helper via `.first(10)` after sorting. Seed at least 3 real entries in both locales for meaningful test coverage.

### Locale Namespace

Extends existing `landing:` namespace. No new top-level key — keeps locale files organized by feature area.

## Code Context

- **Locale files:** `config/locales/ja.yml`, `config/locales/en.yml` — `landing:` namespace starts at line ~156
- **ApplicationHelper:** `app/helpers/application_helper.rb` — existing helpers live here
- **Landing controller:** `app/controllers/landing_controller.rb` — currently `def show; end` (no instance vars needed for helper-based approach)
- **Landing view:** `app/views/landing/show.html.erb` — uses `t('landing.xxx')` pattern throughout
- **Landing CSS:** `app/assets/stylesheets/landing.css.scss` — existing card styles to reuse in Phase 47

## Canonical Refs

- `config/locales/ja.yml` — add `landing.changelog.*` keys
- `config/locales/en.yml` — add `landing.changelog.*` keys
- `app/helpers/application_helper.rb` — add `changelog_entries` method
- `.planning/ROADMAP.md` — Phase 46 success criteria (source of truth for requirements)

## Deferred Ideas

None identified.
