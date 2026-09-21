---
task: obsolete-adr-audit
created: 2026-05-23
---

# Audit: obsolete ADRs

## Goal

Determine whether the repo has Architecture Decision Records (ADRs) and which decision docs are obsolete relative to the current codebase.

## Scope

- Search for formal ADR files (`docs/adr/`, `ADR-*.md`, `decisions/`)
- Cross-check living `.planning/codebase/*` docs against code (post OAuth2 / drop-oauth1 quick task)
- Note planned-but-never-written ADRs

## Out of scope

- Rewriting historical milestone archives under `.planning/milestones/`
- Bulk doc refresh unless explicitly requested
