---
phase: 16
phase_name: Core Shell & Shared Messages Translation
date: 2026-05-01
mode: default
---

# Phase 16 Discussion Log

Human-reference audit log of the discuss-phase session. Not consumed by downstream agents; CONTEXT.md is the canonical record of decisions.

## Gray Areas Presented

1. Key namespace strategy
2. rails-i18n / devise-i18n activation
3. Flash & alert translation pattern
4. Phase 16 vs 17 boundary

User selected: **Flash & alert translation pattern** (only).

## Discussion: Flash & alert translation pattern

### Q1 — Where should shared flash/alert strings live in the locale files?

Options:
- Top-level `flash.*` namespace (Recommended)
- Lazy per-controller (`t('.created')`)
- Hybrid: shared in `flash.*`, action-specific lazy

**Selected:** Top-level `flash.*` namespace.

Rationale (from question text): mirrors existing `messages.confirm_delete` precedent (already top-level absolute-key shared namespace with `%{name}` interpolation, reused across 4 feature views). App has very few flashes, so duplicating shared phrasing across per-controller lazy keys is poor value. Locale-file-anchored keys are immune to controller renames.

### Q2 — How should interpolated subject names work in flashes?

Options:
- Pass record's user-content directly via `name:` (Recommended)
- Use translated model name via `activerecord.models.*`
- Both — separate keys for record-name vs generic forms

**Selected:** Pass record user-content directly.

Rationale: identical to existing `messages.confirm_delete` (`name: @record.title`). Avoids opening the `activerecord.models.*` translation surface in this phase.

### Q3 — How should generic error fallbacks be handled?

Options:
- Single shared `flash.errors.generic` key (Recommended)
- Surface `errors.full_messages` directly, no fallback string
- Per-controller specific keys

**Selected:** Single shared `flash.errors.generic` key.

Concrete impact: replace `'エラーが発生しました'` literal in `app/controllers/notes_controller.rb:8` with `t('flash.errors.generic')`. Same key reused anywhere else needing a generic error fallback.

### Q4 — How should validation messages be handled for TRN-04?

Options:
- Activate rails-i18n for both ja/en (Recommended)
- Hand-roll only the keys we hit
- Defer all validation copy to Phase 18

**Selected:** Activate rails-i18n for both ja/en.

Concrete impact: `gem 'rails-i18n', '~> 8.0'` is already in Gemfile; Phase 16 verifies that both `:en` and `:ja` defaults from rails-i18n actually load and that `errors.full_messages` produces localized output in each locale. `devise-i18n` is intentionally NOT activated in Phase 16 — deferred to Phase 18.

## Deferred Items

The user did not select the other three gray areas. Their decision is intentionally deferred to research/planning:

- Key namespace strategy for non-flash shell strings (nav, layout title, ARIA)
- Phase 16 vs 17 boundary on shared form text
- Test coverage approach for TRN-01 / TRN-04 (parity test, integration tests, Cucumber scope)

These appear in the `<deferred>` section of CONTEXT.md with researcher/planner guidance.

## Scope Creep

None surfaced.

## Notes

- `gsd-sdk` CLI was not available in this session; init/state recording done manually.
- Discussion checkpoint file was not written (no inter-area pauses).
</content>
</invoke>