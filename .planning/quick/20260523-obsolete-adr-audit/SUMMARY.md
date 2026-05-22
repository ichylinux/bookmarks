---
status: complete
---

# Quick Task: Obsolete ADR audit

## Finding: no formal ADRs

The repository has **no ADR directory or ADR-numbered files** (`docs/adr/`, `ADR-*.md`, `decisions/`). Architecture choices live in:

- `.planning/**/CONTEXT.md`, `*-DISCUSSION-LOG.md`, milestone ROADMAP/REQUIREMENTS (historical)
- `.planning/codebase/*.md` (intended as living codebase intelligence)
- `.planning/PROJECT.md` decision tables

## Finding: planned ADR never written

`.planning/todos/completed/2026-05-19-investigate-x-api-bearer-token-auth.md` step 4 asked to "Document decision as an ADR regardless of outcome." No ADR was added. The outcome is captured instead in `.planning/quick/20260521-drop-oauth1-x-api/SUMMARY.md` (OAuth 2.0 Bearer only).

## Obsolete *living* docs (not ADRs, but stale decisions)

These still describe **OAuth 1.0a**, `token`/`token_secret`, `faraday-oauth1`, or `omniauth-twitter`, which were removed 2026-05-21:

| File | Issue |
|------|--------|
| `.planning/codebase/CONCERNS.md` | Encryption keys list `users.token`; omniauth-twitter / faraday-oauth1 HIGH items |
| `.planning/codebase/ARCHITECTURE.md` | `encrypts :token, :token_secret` |
| `.planning/codebase/INTEGRATIONS.md` | X integration section is OAuth 1.0a |
| `.planning/codebase/STACK.md` | Lists omniauth-twitter, faraday-oauth1 |
| `.planning/codebase/TESTING.md` | Fixture example uses `token_secret` |
| `.planning/todos/completed/2026-05-19-investigate-x-api-bearer-token-auth.md` | Entire problem statement assumes OAuth1 stack |

**Current truth (code):** `omniauth-twitter2`, `oauth2_token` / `oauth2_refresh_token`, `XClient` Bearer + refresh — see `app/models/user.rb`, `app/services/x_client.rb`, quick task `drop-oauth1-x-api`.

## Not obsolete (keep as history)

- `.planning/milestones/v1.18-*` and other shipped milestone archives
- `.planning/PROJECT.md` / `MILESTONES.md` v1.18 narrative lines (historical shipped record)
- `.planning/quick/20260521-drop-oauth1-x-api/` (records the migration)

## Recommendation

1. **Do not delete** non-existent ADRs.
2. If refreshing docs: run `/gsd-docs-update` or a focused quick task on `.planning/codebase/*.md` only.
3. Optionally add a short ADR (or PROJECT.md decision row) stating "X API auth = OAuth 2.0 user Bearer only" and link `drop-oauth1-x-api` SUMMARY — closes the 2026-05-19 todo gap.
4. Mark or archive `2026-05-19-investigate-x-api-bearer-token-auth.md` as superseded (optional).

## Verification

- `Glob **/*ADR*` → 0 files
- `grep oauth1|token_secret` in `app/` → 0 matches (code clean)
- Living stale refs confined to `.planning/codebase/*` and one completed todo
