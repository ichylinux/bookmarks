---
phase: "37"
plan_id: "037-01"
status: complete
created: "2026-05-06T20:30:00+09:00"
---

# Plan 037-01 Summary

## What Changed

- Implemented a shared typography contract in `common.css.scss` using `--font-size-medium-baseline` and `--font-size-scale`.
- Set `medium` baseline to `14px` on desktop and `16px` on mobile (`max-width: 767px`).
- Converted `small` and `large` classes to relative multipliers (`0.875x`, `1.125x`).
- Updated high-impact modern/classic/simple selectors to `rem`/`inherit` so theme layers follow body class authority.
- Centralized invalid font-size fallback through `Preference.normalize_font_size` and helper usage.

## Verification Notes

- Existing preference options remain `small|medium|large`.
- Invalid stored values resolve to `font-size-medium` class safely.
