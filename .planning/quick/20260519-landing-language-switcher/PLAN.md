---
slug: landing-language-switcher
date: 2026-05-19
---

# Landing Language Switcher

Guest users should be able to manually select the language of the landing page because auto-detection via Accept-Language header may be wrong.

## Changes

1. **`localization.rb`** — add `guest_session_locale` candidate:
   - If guest, check `params[:locale]`; if valid, save to `session[:guest_locale]`
   - Return `session[:guest_locale]` so the choice persists across page loads

2. **`_landing.html.erb`** — add language switcher links (`?locale=ja` / `?locale=en`)

3. **`landing.css.scss`** — minimal styles for `.landing-lang-switcher`
