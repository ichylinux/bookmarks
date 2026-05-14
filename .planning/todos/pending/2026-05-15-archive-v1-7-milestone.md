---
created: 2026-05-15T00:00:00+09:00
title: Archive missing v1.7 milestone (ROADMAP snapshot + link)
area: planning
files:
  - .planning/ROADMAP.md
  - .planning/milestones/
---

## Problem

`/gsd-health` (2026-05-15) flagged W006: v1.7 (Mobile Portal Layout, Phases 26–28, shipped 2026-05-04) is listed as ✅ in `ROADMAP.md` but has no `[archived]` link and no snapshot file in `milestones/`. All other milestones from v1.8 onward have `milestones/v{X.Y}-ROADMAP.md` archives. v1.7 was apparently shipped before the archiving convention was established.

## Solution

1. Create `milestones/v1.7-ROADMAP.md` — reconstruct from the v1.7 section in `ROADMAP.md` (Phases 26–28 details are likely still present in the collapsed `<details>` block).
2. Add `— [archived](milestones/v1.7-ROADMAP.md)` to the v1.7 ROADMAP entry in `.planning/ROADMAP.md`.
3. Commit.
