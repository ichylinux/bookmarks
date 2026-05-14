---
created: 2026-05-15T00:00:00+09:00
title: Move misplaced milestone audit files to milestones/
area: planning
files:
  - .planning/v1.7-MILESTONE-AUDIT.md
  - .planning/v1.8-MILESTONE-AUDIT.md
  - .planning/v1.11-MILESTONE-AUDIT.md
  - .planning/v1.12-MILESTONE-AUDIT.md
  - .planning/v1.18-MILESTONE-AUDIT.md
---

## Problem

`/gsd-health` (2026-05-15) flagged W019: five `*-MILESTONE-AUDIT.md` files sit in `.planning/` root instead of the canonical `milestones/` subdirectory. The correct home for audit files is `.planning/milestones/v{X.Y}-MILESTONE-AUDIT.md` (e.g., `v1.16-MILESTONE-AUDIT.md` already lives there correctly).

Affected files:
- `.planning/v1.7-MILESTONE-AUDIT.md`
- `.planning/v1.8-MILESTONE-AUDIT.md`
- `.planning/v1.11-MILESTONE-AUDIT.md`
- `.planning/v1.12-MILESTONE-AUDIT.md`
- `.planning/v1.18-MILESTONE-AUDIT.md`

## Solution

`git mv` each file from `.planning/` to `.planning/milestones/` and commit. No content changes needed — pure relocation.
