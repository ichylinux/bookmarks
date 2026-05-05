# Phase 34: Inventory and `faraday` Migration Path - Context

**Gathered:** 2026-05-05
**Status:** Ready for planning

<domain>
## Phase Boundary

This phase delivers a complete inventory of `httparty` usage across agreed runtime/test/ops paths and defines the migration boundary to `faraday` with behavior parity expectations for migrated paths.

</domain>

<decisions>
## Implementation Decisions

### Inventory Boundary
- **D-01:** Inventory coverage includes `app/`, `lib/`, `test/`, `features/`, `bin/`, `script/`, and root operational entrypoints such as `Rakefile`.
- **D-02:** Inventory scan excludes `.planning/` and `vendor/` to avoid planning-doc and vendored-code noise.
- **D-03:** Phase 34 completion requires `httparty` references to be removed from runtime source scope and `Gemfile`; `Gemfile.lock` cleanup is explicitly deferred to Phase 35.

### Evidence Contract
- **D-04:** Context and downstream artifacts must record the exact inventory command(s) used and hit counts.
- **D-05:** If any hit remains, artifacts must include file-path evidence list for unresolved references.

### Scope Guardrail
- **D-06:** No new feature or external API behavior changes are introduced in this phase; the objective is dependency-surface consolidation and migration-path clarity.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

- `.planning/ROADMAP.md` — Phase 34 goal, requirements, and success criteria.
- `.planning/REQUIREMENTS.md` — `HTTP-01`, `HTTP-02` and traceability mapping.
- `.planning/PROJECT.md` — current milestone objective and active requirement framing.
- `Gemfile` — dependency declaration baseline (`httparty` removal target in Phase 34).
- `Gemfile.lock` — lockfile state baseline (cleanup deferred to Phase 35 by decision).
- `.planning/codebase/STACK.md` — documented presence of both `httparty` and `faraday`.
- `.planning/codebase/INTEGRATIONS.md` — feed/integration HTTP client context.
- `.planning/codebase/ARCHITECTURE.md` — existing `Daddy::HttpClient`/Faraday architectural pattern.
- `.planning/codebase/CONCERNS.md` — pre-identified concern that `httparty` appears unused.
- `app/controllers/bookmarks_controller.rb` — existing `Faraday` usage reference (`fetch_title`) for parity-oriented migration pattern.
- `CLAUDE.md` — verification policy and test gate requirements (`lint`, `rails test`, `dad:test` with flake rerun policy).

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `BookmarksController#fetch_title` already uses `Faraday.new` with explicit timeout/open_timeout and redirect middleware; this is a local example of desired client style.
- `Feed` path uses `Daddy::HttpClient` (Faraday-backed), indicating existing architectural acceptance of Faraday semantics.

### Established Patterns
- External HTTP behavior in this app is expected to remain synchronous and controller/model-compatible within the current Rails/Sprockets stack.
- Planning artifacts treat dependency cleanup and behavior hardening as separate phases; this phase should avoid lockfile-risk coupling beyond agreed boundary.

### Integration Points
- Dependency declaration/update boundary: `Gemfile` now, `Gemfile.lock` in next phase.
- Regression contract boundary: runtime/test/ops paths scanned in inventory scope must be reported with command evidence.

</code_context>

<specifics>
## Specific Ideas

- Use a deterministic ripgrep scan over the agreed directories and report both command and result count.
- Maintain a strict "inventory first, lockfile finalization next phase" sequencing to keep Phase 34 focused and reversible.

</specifics>

<deferred>
## Deferred Ideas

- Behavior-equivalence details (timeout/exception mapping by call-site type) and lockfile finalization strategy are deferred to later discussion/planning steps (Phases 35–36 alignment).

</deferred>

---

*Phase: 034-inventory-and-faraday-migration-path*
*Context gathered: 2026-05-05*
