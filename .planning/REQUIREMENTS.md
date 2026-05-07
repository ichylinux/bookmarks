# Requirements: Bookmarks

**Defined:** 2026-05-08
**Core Value:** Users can quickly capture, find, and manage their own bookmarks and related gadgets in one place, with a stable and familiar server-rendered experience — now in their preferred language.

## v1 Requirements

Requirements for milestone v1.13 (Root Entry Redirect to Landing for Guests).

### Entry Routing

- [x] **ENTRY-02**: Unauthenticated users who access `/` are redirected to `/landing`.
- [x] **ENTRY-03**: Authenticated users who access `/` continue to see the existing dashboard behavior.
- [x] **ENTRY-04**: Direct access to `/landing` remains available for unauthenticated visitors.

### Conversion + Locale Safety

- [x] **LAND-04**: `/landing` keeps visible login/sign-up CTAs after root-entry redirect changes.
- [x] **COMP-03**: Entry routing and landing rendering remain correct under both Japanese and English locale contexts.

### Verification

- [x] **TEST-04**: Automated tests cover auth-state-aware entry routing (`/` guest redirect vs signed-in dashboard).
- [x] **TEST-05**: Automated tests cover locale-aware entry behavior and landing CTA regression contracts.

## v2 Requirements

Deferred to a future milestone.

### Existing-user News

- **NEWS-01**: Existing users can see a simple news section based on existing data sources.
- **NEWS-02**: News items can be categorized and displayed in reverse chronological order on the home surface.

### Entry-point Evolution

- **ENTRY-01**: Evaluate whether full replacement of `/` with landing should remain permanent after conversion observation.

## Out of Scope

Explicitly excluded from this milestone.

| Feature | Reason |
|---------|--------|
| Existing-user news rendering on current home/dashboard | Deferred by user; this milestone focuses only on guest entry routing |
| News authoring/admin UI | Depends on future NEWS requirements and data model decisions |
| Landing content redesign beyond current messaging baseline | Not needed for guest redirect scope; keep v1.12 content stable |
| External feed ingestion for news | Adds integration complexity before entry-routing milestone is validated |

## Traceability

Which phases cover which requirements.

| Requirement | Phase | Status |
|-------------|-------|--------|
| ENTRY-02 | Phase 43 | Satisfied |
| ENTRY-03 | Phase 43 | Satisfied |
| ENTRY-04 | Phase 43 | Satisfied |
| LAND-04 | Phase 44 | Satisfied |
| COMP-03 | Phase 44 | Satisfied |
| TEST-04 | Phase 45 | Satisfied |
| TEST-05 | Phase 45 | Satisfied |

**Coverage:**
- v1 requirements: 7 total
- Mapped to phases: 7
- Unmapped: 0 ✓

---
*Requirements defined: 2026-05-08*
*Last updated: 2026-05-08 after v1.13 phase execution sync*
