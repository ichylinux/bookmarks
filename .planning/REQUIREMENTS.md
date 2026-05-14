# Requirements: v1.20 — Column Count Preference

## Overview

Users can select 3 or 4 portal columns from the preferences screen. The portal renders the correct number of columns on desktop; mobile tab strip behavior is unchanged. Switching between counts is safe in both directions.

## v1 Requirements

### Data Layer

- [ ] **COL-01**: `preferences.portal_column_count` integer column (default 3, NOT NULL); `Preference` model validates value is in [3, 4] and rejects anything else

### Preferences UI

- [ ] **COL-02**: Preferences page shows a select control for portal column count (3 or 4 columns); ja/en locale strings for the label and option values
- [ ] **COL-03**: Submitting the preferences form persists the column count; the select control reflects the saved value on page reload

### Portal Behavior

- [ ] **COL-04**: `Portal#portal_columns` uses `user.preference.portal_column_count` instead of the hardcoded 3; `Portal#portal_column_count` delegates to the preference value
- [ ] **COL-05**: Welcome page renders the correct number of column sections for the user's preference (3 or 4); existing gadget placements in columns 0–2 are preserved when switching to 4; column 3 is empty on first switch to 4
- [ ] **COL-06**: Downgrading from 4 → 3 columns is safe: `Portal#portal_columns` skips `PortalLayout` records with `column_no >= column_count`; those gadgets are redistributed via the existing fallback (`i % column_count`); saved positions in column 3 are restored when switching back to 4

### Test Coverage

- [ ] **COL-07**: Minitest covers preference validation (valid values 3/4, default 3, invalid value rejected), preferences controller (save column count), portal column distribution (3 and 4 columns, downgrade path), and locale key parity for new strings
- [ ] **COL-08**: Tri-suite gate green at milestone close (`yarn run lint` + `bin/rails test` + `bundle exec rake dad:test`)

## Future Requirements (deferred)

- Column counts below 3 (single-column) — mobile already handles this via tab strip; desktop 1-column is not planned
- Per-device column count (different settings for mobile vs desktop)
- Column count above 4

## Out of Scope

- Mobile layout changes — column count applies to desktop rendering only; the mobile tab strip (`show_column_nav_buttons`) is a separate preference and is unaffected
- Drag-and-drop changes — existing drag-and-drop layout saves to `portal_layouts` and continues to work without modification; the 4th column is available as a drag target automatically

## Traceability

| REQ | Phase | Plan | Status |
|-----|-------|------|--------|
| COL-01 | — | — | Pending |
| COL-02 | — | — | Pending |
| COL-03 | — | — | Pending |
| COL-04 | — | — | Pending |
| COL-05 | — | — | Pending |
| COL-06 | — | — | Pending |
| COL-07 | — | — | Pending |
| COL-08 | — | — | Pending |
