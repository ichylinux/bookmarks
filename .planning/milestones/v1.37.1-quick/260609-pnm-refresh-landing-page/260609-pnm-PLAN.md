---
quick_id: 260609-pnm
slug: refresh-landing-page
date: "2026-06-09"
status: planned
---

# Quick Task 260609-pnm: Refresh landing page

## Goal

Bring the guest landing page up to date with product changes shipped since the 2026-05-25 refresh: changelog entries for TODO highlight and bookmark gadget partial reload, refreshed top changelog card, and value-copy tweak for task emphasis.

## Tasks

1. **Locale changelog (ja/en)** — Add 2026-06-09 refresh entry; add entries for TODO highlight (2026-06-09) and bookmark gadget partial reload (2026-06-06)
2. **Value copy** — Update `landing.values.organize.body` to mention task highlight in ja/en
3. **Tests + tri-suite** — Extend `root_path_test` for new changelog headline; run lint + rails test + dad:test
