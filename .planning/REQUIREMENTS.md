# Requirements — v1.22 Landing at Root

## Milestone Goal

Move the landing page to `/` (no redirect), remove the `/landing` route, and fix the deferred Twitter `from_omniauth` uid lookup bug (XAUTH-FUT-01).

---

## v1.22 Requirements

### ROOT — Landing at Root

- [ ] **ROOT-01**: Unauthenticated user visiting `/` sees the landing page content rendered inline — no HTTP redirect to `/landing`
- [ ] **ROOT-02**: Authenticated user visiting `/` continues to see the dashboard (no behavior change)
- [ ] **ROOT-03**: The `/landing` URL is removed from the application (visiting it returns 404 or a routing error)
- [ ] **ROOT-04**: `redirect_guest_to_landing` guard removed from `WelcomeController`; `LandingController` and its route cleaned up
- [ ] **ROOT-05**: Existing tests updated to reflect inline rendering (no redirect assertions); regression tests confirm both auth states at `/`

### XAUTH — Twitter uid Lookup Fix

- [ ] **XAUTH-01**: `User.from_omniauth` Twitter branch looks up an existing user by `uid` instead of `name`
- [ ] **XAUTH-02**: Minitest coverage for uid-based lookup (found, not found / new user paths)

---

## Future Requirements (deferred)

- Per-user landing conversion analytics (decide if `/landing` removal changes any tracking)
- Public SEO/meta tags on `/` for unauthenticated visitors

## Out of Scope

- Landing page content or copy changes — purely routing refactor
- Fallback-to-name lookup for pre-v1.18 Twitter users — personal app with single account; uid persisted since v1.18 Phase 60

---

## Traceability

| REQ-ID | Phase | Plan | Status |
|--------|-------|------|--------|
| ROOT-01 | — | — | — |
| ROOT-02 | — | — | — |
| ROOT-03 | — | — | — |
| ROOT-04 | — | — | — |
| ROOT-05 | — | — | — |
| XAUTH-01 | — | — | — |
| XAUTH-02 | — | — | — |
