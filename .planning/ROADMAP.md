# Roadmap: Bookmarks

## Milestones

- ✅ **v1.1 — Modern JavaScript** — Phases 2–4 (shipped 2026-04-27) — [archived](milestones/v1.1-ROADMAP.md)
- ✅ **v1.2 — Modern Theme** — Phases 5–9 (shipped 2026-04-29) — [archived](milestones/v1.2-ROADMAP.md)
- ✅ **v1.3 — Quick Note Gadget** — Phases 10–13 (shipped 2026-04-30) — [archived](milestones/v1.3-ROADMAP.md)
- ✅ **v1.4 — Internationalization** — Phases 14–18.2 (shipped 2026-05-03) — [archived](milestones/v1.4-ROADMAP.md)
- ✅ **v1.5 — Verification Debt Cleanup** — Phases 19–22 (shipped 2026-05-04) — [archived](milestones/v1.5-ROADMAP.md)
- ✅ **v1.6 — Note Gadget for All Themes** — Phases 23–25 (shipped 2026-05-04) — [archived](milestones/v1.6-ROADMAP.md)
- ✅ **v1.7 — Mobile Portal Layout** — Phases 26–28 (shipped 2026-05-04)
- ✅ **v1.8 — Mobile UX Enhancement** — Phases 29–32.1 (shipped 2026-05-05) — [archived](milestones/v1.8-ROADMAP.md)
- ✅ **v1.9 — Mobile Regression Hardening** — Phases 33–33.2 (shipped 2026-05-05) — [archived](milestones/v1.9-ROADMAP.md)
- ◆ **v1.10 — HTTP Client Consolidation** — Phases 34–36 (planning)

## Phases

### Phase 34 — Inventory and `faraday` Migration Path

**Goal:** Identify every `httparty` usage path and migrate request-building/response-handling flows to `faraday` with behavior parity.

**Requirements:** HTTP-01, HTTP-02

**Success Criteria:**
1. All direct `httparty` call sites are replaced with `faraday` in application code.
2. Request method/header/payload/query behavior matches pre-migration behavior on migrated paths.
3. Response parsing and downstream call contracts remain backward-compatible.

### Phase 35 — Error Handling Parity and Dependency Removal

**Goal:** Preserve failure-path behavior and remove `httparty` dependency from runtime.

**Requirements:** HTTP-03, HTTP-04

**Success Criteria:**
1. Timeout, connection-failure, and non-success response handling behavior is preserved under `faraday`.
2. `httparty` is removed from `Gemfile`/`Gemfile.lock` with no residual runtime references.
3. Application boots and relevant integration paths execute without `httparty` installed.

### Phase 36 — Regression Proof and Verification Gate

**Goal:** Lock migration with automated regression coverage and complete milestone verification.

**Requirements:** HTTP-05

**Success Criteria:**
1. Existing tests are updated and/or new tests are added for migrated HTTP integrations.
2. `yarn run lint` passes.
3. `bin/rails test` passes.
4. `bundle exec rake dad:test` passes (with one rerun allowed per flake policy).

---
*Last updated: 2026-05-05 — v1.10 roadmap created.*
