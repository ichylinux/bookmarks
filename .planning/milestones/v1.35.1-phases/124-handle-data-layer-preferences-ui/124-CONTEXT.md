# Phase 124: Handle Data Layer & Preferences UI - Context

**Gathered:** 2026-06-16
**Status:** Ready for planning
**Mode:** Auto-approved (autonomous smart discuss)

<domain>
## Phase Boundary

Users can register a canonical Mastodon handle (`localpart@instance`) on `/preferences` with input normalization, localized validation errors, and DB-level uniqueness for non-blank values. OAuth identity wiring (Phase 125) and tri-suite gate (Phase 126) are out of scope.

</domain>

<decisions>
## Implementation Decisions

### Normalizer Service
- Place `MastodonHandleNormalizer` in `app/services/` mirroring `MastodonInstanceNormalizer` pattern (Result struct with `success?` and `error_key`)
- Accept `@user@instance`, bare `user@instance`, and URL-ish input (`https://instance/@user`); output canonical `localpart@instance` or error key (`:blank`, `:invalid`, `:missing_separator`)
- Downcase instance hostname only; preserve localpart casing as entered (Mastodon localparts are case-sensitive per instance)
- Blank input normalizes to `nil` (not empty string)

### Model & Database
- Column migration `add_column_mastodon_handle_on_users` already exists; add separate migration for unique index on `users.mastodon_handle` (MySQL allows multiple NULLs on unique index)
- `before_validation :normalize_mastodon_handle` on User; validate format and uniqueness on update when attribute is present
- Uniqueness scoped to non-blank values only; multiple users may have NULL/blank handle

### Preferences UI & Controller
- `mastodon_handle` is a top-level User attribute (not nested under preference) — field row in preferences table before connected_accounts partial
- `PreferencesController#user_params` permits `:mastodon_handle` at user level alongside `preference_attributes`
- Text field with label, placeholder `user@mastodon.social`, and brief help text below input; validation errors via standard `form_with` model errors

### Locales & Tests
- ja/en keys under `preferences.mastodon_handle` (label, placeholder, help) and `activerecord.errors.models.user.attributes.mastodon_handle` (invalid, taken)
- i18n parity test for new keys; Minitest for normalizer, model validation/uniqueness, preferences save round-trip

### Claude's Discretion
- Exact regex for localpart validation (follow Mastodon conventions: alphanumeric + underscore, max 30 chars)
- Whether to add normalizer unit tests as separate file vs inline in model test

</decisions>

<code_context>
## Existing Code Insights

### Reusable Assets
- `MastodonInstanceNormalizer` — service object pattern with Result struct, hostname validation, strip helpers
- `PreferencesController` — nested `preference_attributes` pattern; add top-level `:mastodon_handle` permit
- `preferences/index.html.erb` — table-row form layout; connected_accounts rendered below form
- Migration `20260616125530_add_column_mastodon_handle_on_users.rb` — column already added, needs unique index migration

### Established Patterns
- Service objects in `app/services/` with `.normalize` class method
- Bilingual locales in `config/locales/ja.yml` and `en.yml` with i18n parity tests
- Preferences controller integration tests in `test/controllers/preferences_controller_test.rb`

### Integration Points
- `User` model — add validation and normalization callback
- `PreferencesController#user_params` — permit new attribute
- `preferences/index.html.erb` — new table row for handle field
- `db/schema.rb` — unique index after migration

</code_context>

<specifics>
## Specific Ideas

- Follow v1.35 `MastodonInstanceNormalizer` conventions for consistency
- Placeholder `user@mastodon.social` per REQUIREMENTS VIEW-04
- No WebFinger validation at save time (explicitly out of scope per REQUIREMENTS)

</specifics>

<deferred>
## Deferred Ideas

- Auto-populate `mastodon_handle` after first Mastodon OAuth (HDL-FUT-01 — v2)
- Connect Mastodon from preferences without OAuth (IDNT-FUT-01 — v2)

</deferred>
