---
slug: refresh-landing-page
date: "2026-05-19"
status: in_progress
---

# Quick Task: Refresh Landing Page

Sync the landing page changelog so it reflects all recent features. Two issues to fix:

1. **English locale missing 2 entries** that exist in Japanese (visited-links feature + fix)
2. **Both locales missing** the new bookmark dialog feature added 2026-05-19

## Changes

### 1. `config/locales/en.yml` — add 3 missing entries (prepend before 2026-05-18 portal-width entry)
- `2026-05-19` fix: visited-links recording bug fix
- `2026-05-18` new: visited links (greyed-out clicked links across gadgets)
- `2026-05-19` new: add bookmark from dashboard (new bookmark dialog)

### 2. `config/locales/ja.yml` — add 1 missing entry (prepend before 2026-05-19 visited-links fix)
- `2026-05-19` new: ダッシュボードからブックマークを追加できるようになりました

## Order (newest first)
- 2026-05-19 new: bookmark dialog (both locales)
- 2026-05-19 fix: visited-links fix (both locales — already in ja)
- 2026-05-18 new: visited links feature (both locales — already in ja)
- 2026-05-18 new: portal column widths (already in both)
