---
slug: landing-language-switcher
status: complete
date: 2026-05-19
---

# Summary

Added a language switcher to the landing page so guest users can manually select Japanese or English regardless of browser Accept-Language header.

## Changes

- `localization.rb`: added `guest_session_locale` — reads `params[:locale]`, validates, saves to `session[:guest_locale]`, persists across page loads for guests
- `_landing.html.erb`: added `.landing-lang-switcher` with 日本語 / English links (active state highlights current locale)
- `landing.css.scss`: added styles for `.landing-lang-switcher` and `.landing-lang-link`

## Tests

- `bin/rails test` — 458 runs, 0 failures
