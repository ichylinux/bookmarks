# Requirements: v1.14 Landing Page Changelog

## Milestone Goal

Add a curated "What's New" section to `/landing` that shows visitors recent UX improvements as rich dated cards, backed by locale YAML and bilingual in Japanese and English.

## v1.14 Requirements

### Changelog Data (CLOG)

- [x] **CLOG-01**: Changelog entries are defined in locale YAML (ja/en) — each entry has a date, headline, tag, and description
- [x] **CLOG-02**: Up to 10 most recent entries are shown on `/landing`
- [x] **CLOG-03**: Tags categorize entries (e.g., UX, Fix, Performance) and are rendered as a visible label on each card
- [x] **CLOG-04**: The changelog section has a localized section heading ("What's New" / 「新着情報」)

### Landing View (VIEW)

- [ ] **VIEW-01**: The "What's New" section renders below the existing value-grid on `/landing`
- [ ] **VIEW-02**: Each card shows: date, tag label, headline, description — styled consistently with the landing page
- [ ] **VIEW-03**: The section renders correctly for all visitors (guests and redirected signed-in users)

### Verification (VERF)

- [ ] **VERF-01**: Controller/view tests confirm changelog section renders on `/landing` with correct locale keys
- [ ] **VERF-02**: Locale key parity between ja.yml and en.yml is enforced (consistent with existing parity tests)

## Future Requirements

- Interactive filtering by tag (UX / Fix / Performance)
- Pagination or "show all" link for entries beyond 10
- Per-user "last seen" tracking to highlight new entries since last visit
- Admin UI for managing entries without editing YAML directly

## Out of Scope

- Database-backed changelog (static YAML is the source of truth for this milestone)
- Git commit parsing — entries are manually curated
- Real-time update mechanism
- Separate `/changelog` route (section lives on `/landing` only)
- Email notification of new entries

## Traceability

| REQ-ID | Phase | Plan |
|--------|-------|------|
| CLOG-01 | Phase 46 | 046-01 |
| CLOG-02 | Phase 46 | 046-01 |
| CLOG-03 | Phase 46 | 046-01 |
| CLOG-04 | Phase 46 | 046-01 |
| VIEW-01 | Phase 47 | — |
| VIEW-02 | Phase 47 | — |
| VIEW-03 | Phase 47 | — |
| VERF-01 | Phase 48 | — |
| VERF-02 | Phase 48 | — |
