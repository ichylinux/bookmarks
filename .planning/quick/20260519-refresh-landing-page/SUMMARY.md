---
slug: refresh-landing-page
date: "2026-05-19"
status: complete
commit: d3470d7
---

# Summary: Refresh Landing Page

Added missing changelog entries to bring the landing page up to date with recent shipping.

## What changed
- **en.yml**: added 3 entries — bookmark dialog (new), visited-links fix, visited-links feature
- **ja.yml**: added 1 entry — bookmark dialog (new); visited-link entries were already present

## Why English was behind
The `17d6fba` commit only updated `ja.yml` for the visited-links changelog entries; English was never synced.
