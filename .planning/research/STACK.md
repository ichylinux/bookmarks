# Technology Stack — v1.5 Verification Debt Cleanup

**Project:** Bookmarks (Rails 8.1)  
**Milestone:** v1.5 Verification Debt Cleanup  
**Researched:** 2026-05-03

## Recommendation

Preserve the current stack and close debt with process discipline, not new tools.

## Required

1. Use the existing 3-suite contract for verification evidence:
   - `yarn run lint`
   - `bin/rails test`
   - `bundle exec rake dad:test`
2. Capture reproducible metadata in each verification document:
   - commit SHA, commands, results, and rerun notes.
3. For verification evidence runs, prefer deterministic Cucumber order:
   - `SORT=true bundle exec rake dad:test`
4. If verification reveals scenario-order leakage, apply a minimal `features/support` state-reset hook (no wider test-stack changes).

## Optional

- A tiny helper script/rake wrapper for v1.5 evidence collection.
- One informational coverage snapshot (`COVERAGE=true`) without adding a gate.

## Do Not Add in This Milestone

- New test frameworks or runner migration
- Third-party reporting platforms
- Parallelization/infrastructure overhauls
- Frontend/build stack changes

## Integration Notes

- Reuse existing artifact locations (`test/reports`, `features/reports`).
- Keep `bundle exec rake dad:test` as the canonical Cucumber entrypoint.
- Keep fixes surgical and directly tied to failed verification claims.
