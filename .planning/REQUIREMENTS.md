# Requirements: Bookmarks

**Defined:** 2026-05-05
**Core Value:** Users can quickly capture, find, and manage their own bookmarks and related gadgets in one place, with a stable and familiar server-rendered experience — now in their preferred language.

## v1 Requirements

Requirements for milestone v1.10 (HTTP Client Consolidation). Each maps to exactly one roadmap phase.

### HTTP Client Consolidation

- [ ] **HTTP-01**: User-facing functionality remains unchanged while all existing `httparty` call paths are migrated to `faraday`
- [ ] **HTTP-02**: Requests preserve existing behavior for HTTP method, headers, payload/query encoding, and response parsing after migration
- [ ] **HTTP-03**: Existing error-handling behavior is preserved for timeout, connection failure, and non-success responses
- [ ] **HTTP-04**: `httparty` is removed from dependencies and the app boots/tests without any `httparty` runtime dependency
- [ ] **HTTP-05**: Automated test coverage prevents regression on migrated HTTP integration paths

## v2 Requirements

Deferred to a future milestone.

### HTTP Infrastructure

- **HTTPI-01**: Standardize shared `faraday` middleware policy (retry/observability) across all external integrations

## Out of Scope

Explicitly excluded from this milestone.

| Feature | Reason |
|---------|--------|
| External API contract changes | Goal is dependency consolidation, not product behavior change |
| External service/provider replacement | Independent initiative with broader risk and scope |
| UI/UX changes unrelated to HTTP migration | Not required for dependency simplification |

## Traceability

Which phases cover which requirements. Updated from the approved roadmap.

| Requirement | Phase | Status |
|-------------|-------|--------|
| HTTP-01 | Phase 34 | Pending |
| HTTP-02 | Phase 34 | Pending |
| HTTP-03 | Phase 35 | Pending |
| HTTP-04 | Phase 35 | Pending |
| HTTP-05 | Phase 36 | Pending |

**Coverage:**
- v1 requirements: 5 total
- Mapped to phases: 5
- Unmapped: 0 ✓

---
*Requirements defined: 2026-05-05*
*Last updated: 2026-05-05 after v1.10 initial definition*
