# Requirements: Bookmarks

**Defined:** 2026-04-27  
**Core Value:** Users can quickly capture, find, and manage their own bookmarks and related gadgets in one place, with a stable and familiar server-rendered experience.

## v1 Requirements

Scope for milestone **v1.1 — Modern JavaScript**. Each item maps to roadmap phases (traceability below).

### Tooling (TOOL)

- [x] **TOOL-01**: Project has a checkable JavaScript style baseline (ESLint and/or Prettier, or an explicitly documented alternative) that runs in development/CI or via clear documented commands, aligned with Sprockets and Babel
- [x] **TOOL-02**: `package.json` (or project docs) documents how to run lint/format so contributors repeat the same checks

### Code style (STYL)

- [x] **STYL-01**: In-repository application scripts under `app/assets/javascripts/` (excluding vendored third-party if any) use `const`/`let` instead of `var` except where a documented exception is required
- [x] **STYL-02**: Event handlers and callbacks use modern patterns (e.g. arrow functions) where it reduces noise and does not break jQuery `this` semantics; document the rule for `this` usage
- [x] **STYL-03**: No new accidental globals; existing namespace patterns are preserved or replaced with a clear module pattern that works with the asset pipeline
- [x] **STYL-04**: `babel.config.js` and build expectations remain valid after style changes; production asset precompilation still succeeds

### Quality & verification (VERI)

- [ ] **VERI-01**: Automated test suite (Minitest, Cucumber as applicable) passes with no new failures attributable to JavaScript changes
- [ ] **VERI-02**: Critical user flows that depend on browser JS (e.g. bookmark title auto-fill, feed/todo/calendar/gadget behaviour if present) are smoke-checked after changes
- [ ] **VERI-03**: No user-visible functional regressions in form submissions, UJS, or `.js.erb` responses related to modified scripts

### Documentation (DOCS)

- [ ] **DOCS-01**: `.planning/codebase/CONVENTIONS.md` (or a dedicated `docs/` note linked from it) is updated with JavaScript conventions for this project so future code matches the milestone outcome

## v2 Requirements (deferred)

| ID | Item |
|----|------|
| TS-01 | TypeScript or JSDoc typing for new JS (evaluate after v1.1) |
| FE-01 | Migration off Sprockets to a bundler (only if product strategy changes) |
| FE-02 | New SPA framework (out of current product direction) |

## Out of Scope

| Item | Reason |
|------|--------|
| New UI framework (React, Vue, etc.) | v1.1 is style/tooling, not a rewrite |
| Full npm runtime dependency graph for app JS | Keep aligned with current gem + minimal Node tooling model unless separately approved |
| Rewriting all Ruby/ERB | Milestone is JavaScript-focused |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| TOOL-01 | Phase 2 | Complete |
| TOOL-02 | Phase 2 | Complete |
| STYL-01 | Phase 3 | Complete |
| STYL-02 | Phase 3 | Complete |
| STYL-03 | Phase 3 | Complete |
| STYL-04 | Phase 3 | Complete |
| VERI-01 | Phase 4 | Pending |
| VERI-02 | Phase 4 | Pending |
| VERI-03 | Phase 4 | Pending |
| DOCS-01 | Phase 4 | Pending |

**Coverage:**  
- v1 requirements: 10 total  
- Mapped to phases: 10  
- Unmapped: 0 ✓

---
*Requirements defined: 2026-04-27*  
*Last updated: 2026-04-27 after roadmap creation*
