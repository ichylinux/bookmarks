# Phase 120: Instance Selection UI - Context

**Gathered:** 2026-06-12
**Status:** Ready for planning
**Mode:** Auto-generated (autonomous smart discuss — recommendations accepted)

<domain>
## Phase Boundary

Add Mastodon instance domain input on sign-in and sign-up pages. User enters domain (e.g. `mastodon.social`), form POST validates and normalizes it, stores in `session[:mastodon_instance]`, then redirects to `/users/auth/mastodon`. Invalid input shows localized flash without starting OAuth. Does NOT include Mastodon OAuth button styling (Phase 122) or `from_omniauth` (Phase 121).

</domain>

<decisions>
## Implementation Decisions

### Form Layout
- Instance input + submit grouped below existing OAuth buttons in `_oauth_buttons.html.erb` partial (shared by sign-in and sign-up)
- Single-line text input for domain only (no `https://` prefix shown — user enters hostname)
- Submit button labeled "Sign in with Mastodon" / localized equivalent — triggers instance form POST, not direct OmniAuth link

### Validation & Normalization
- Strip `https://`, `http://`, trailing slashes, and leading `@`
- Reject blank, strings containing `/` path segments, invalid hostnames (no dots for multi-label, or IP literals)
- Reject scheme-prefixed input that survives stripping (malformed)
- Normalize to lowercase hostname
- Store normalized domain in `session[:mastodon_instance]` (hostname only, no scheme)

### Controller & Routes
- New controller action (e.g. `MastodonSessionsController#set_instance` or nested under devise) handling POST
- On success: redirect to `omniauth_authorize_path(:user, :mastodon)`
- On failure: redirect back to referrer (sign-in or sign-up) with flash alert

### Locale
- ja/en keys for instance input label, placeholder, submit button, and validation error messages
- Follow existing `devise.shared.omniauth.*` key namespace pattern

### Claude's Discretion
- Exact route path and controller name
- Hostname validation regex strictness (balance UX vs SSRF prevention per PITFALLS.md)

</decisions>

<code_context>
## Existing Code Insights

### Reusable Assets
- `app/views/devise/shared/_oauth_buttons.html.erb` — existing Google/X/Facebook buttons with `auth-oauth-btn` CSS classes
- Auth page layouts include this partial on both sessions#new and registrations#new
- `session[:mastodon_instance]` already read by `OmniAuth::Strategies::Mastodon` (Phase 119)

### Established Patterns
- `button_to` with `data: { turbo: false }` for OAuth buttons
- Locale keys under `devise.shared.omniauth.*`
- Flash messages for validation errors on auth pages

### Integration Points
- Form POST must set session before redirect to `/users/auth/mastodon`
- Strategy's `mastodon_site` reads `session[:mastodon_instance]`

</code_context>

<specifics>
## Specific Ideas

- Match visual density of existing OAuth button row — instance form is a compact inline or stacked group
- Facebook button hidden in production — Mastodon form visible in all environments

</specifics>

<deferred>
## Deferred Ideas

- Mastodon branded button/icon (Phase 122)
- Connected Accounts Mastodon row (Phase 122)
- Hostname blocklist for SSRF (optional hardening — defer unless trivial)

</deferred>
