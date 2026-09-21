---
slug: refresh-landing-page
date: "2026-05-25"
status: complete
---

# Quick Task: Refresh landing page

## Goal

Modernize the guest landing page: hero aligned with auth surfaces, integrations reflect all sign-in providers (Google, X, Facebook, Mastodon), changelog covers recent OAuth milestones.

## Tasks

1. Update `_landing.html.erb` — brand lockup in hero; four integration cards
2. Refresh `landing.css.scss` — gradient hero, 2×2 integration grid
3. Locale copy (ja/en) — integration bodies for Google/Facebook; changelog entries
4. Extend `root_path_test` for new integration headings; run tri-suite gate
