---
plan: 89-02
phase: 89-static-policy-pages
status: completed
completed_at: "2026-05-19"
---

# Plan 89-02 Summary — Views and Locale YAML

## What Was Built

- **`config/locales/ja.yml`** — Added `pages:` namespace with full Japanese prose for privacy (5 sections) and terms (3 sections)
- **`config/locales/en.yml`** — Added `pages:` namespace with full English prose for privacy (5 sections) and terms (3 sections)
- **`app/views/pages/privacy.html.erb`** — Bilingual privacy policy view: `main.landing-page` wrapper, lang switcher with `aria-current`, `.policy-back-link`, `article.policy-content` with h1 + 5 section loop via `simple_format(t(...))`
- **`app/views/pages/terms.html.erb`** — Identical structure for terms of service with 3 sections

## Test Results

| Suite | Result |
|-------|--------|
| `bin/rails test test/controllers/privacy_controller_test.rb test/controllers/terms_controller_test.rb` | 12 runs, 0 failures |
| `bin/rails test` | 482 runs, 0 failures |
| `yarn run lint` | green |
| `bundle exec rake dad:test` | 27/27 passed (1 pre-existing order-dependent flake on runs 1–2, resolved on run 3 per CLAUDE.md policy) |
| Human checkpoint | approved |

## Requirements Closed

- **PRIV-01**: GET /privacy returns 200 without authentication ✓
- **PRIV-02**: Privacy page bilingual (ja/en) with locale switcher ✓
- **PRIV-03**: 5 sections — data_collected, x_login, email_handling, data_retention, contact ✓
- **TOS-01**: GET /terms returns 200 without authentication ✓
- **TOS-02**: Terms page bilingual (ja/en) with locale switcher ✓
- **TOS-03**: 3 sections — acceptable_use, availability, termination ✓

## Commits

- `feat(89-02): add bilingual views and locale YAML for policy pages`
