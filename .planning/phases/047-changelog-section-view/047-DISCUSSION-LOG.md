# Discussion Log — Phase 47: Changelog Section View

**Date:** 2026-05-10
**Mode:** autonomous (auto-answered — all decisions made by Claude)

## Areas Discussed

### 1. Card Layout
- **Decision:** Single-column stacked list (full-width cards)
- **Rationale:** Description text is narrative; full width reads better than a grid

### 2. Visual Style
- **Decision:** New `.changelog-card` class, same pattern as `.landing-value-card`
- **Rationale:** Separate class for future flexibility; identical visual baseline

### 3. Tag Badge Treatment
- **Decision:** Colored pill badge (`.changelog-tag--{key}`) with 4 color variants
- **Rationale:** Color coding makes tags scannable; consistent with existing brand colors

### 4. Date Display
- **Decision:** Raw `YYYY-MM-DD` in `<time>` element
- **Rationale:** Data is already formatted; no parsing overhead; `datetime` attr for accessibility

### 5. Section Placement
- **Decision:** After `.landing-value-grid` in `show.html.erb`
- **Rationale:** Matches ROADMAP.md success criterion ("below the value grid")

## Deferred Ideas

None.
