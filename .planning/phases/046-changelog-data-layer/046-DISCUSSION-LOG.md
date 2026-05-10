# Discussion Log — Phase 46: Changelog Data Layer

**Date:** 2026-05-10
**Mode:** autonomous (auto-answered — all decisions made by Claude)

## Areas Discussed

### 1. YAML Entry Structure
- **Decision:** Array of hashes under `landing.changelog.entries`
- **Rationale:** Rails i18n supports YAML arrays natively; keeps changelog in existing `landing:` namespace

### 2. Tag Taxonomy
- **Decision:** Four tags (ux, fix, performance, new) as locale keys under `landing.changelog.tags`
- **Rationale:** Locale-backed rendering ensures bilingual tag labels; extensible without code changes

### 3. Helper Placement
- **Decision:** `changelog_entries` method in `ApplicationHelper`
- **Rationale:** No existing `LandingHelper`; one method doesn't warrant a new file

### 4. Sort / Cap Logic
- **Decision:** Sort by date desc, cap at 10 in the helper
- **Rationale:** ROADMAP.md requirement; helper is the canonical data access point

## Deferred Ideas

None.
