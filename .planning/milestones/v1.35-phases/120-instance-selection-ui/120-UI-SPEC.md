---
phase: 120
slug: instance-selection-ui
status: approved
shadcn_initialized: false
preset: none
created: 2026-06-12
---

# Phase 120 — UI Design Contract

> Visual and interaction contract for Mastodon instance selection on auth pages.

---

## Design System

| Property | Value |
|----------|-------|
| Tool | none (Rails ERB + existing devise.css.scss) |
| Preset | auth-flow existing |
| Component library | none |
| Icon library | none (Phase 122 adds branded button) |
| Font | inherit from auth-flow |

---

## Spacing Scale

Declared values (must be multiples of 4):

| Token | Value | Usage |
|-------|-------|-------|
| xs | 4px | Form internal gaps |
| sm | 8px | Label-to-input gap |
| md | 12px | Match `.auth-oauth-buttons` gap |
| lg | 20px | Section margin-top (match `.auth-oauth-primary`) |
| xl | 24px | Divider spacing |

Exceptions: none

---

## Typography

| Role | Size | Weight | Line Height |
|------|------|--------|-------------|
| Body | 15px | 400 | 1.4 |
| Label | 13px | 600 | 1.3 |
| Submit | 15px | 600 | 1 |

---

## Color

| Role | Value | Usage |
|------|-------|-------|
| Dominant (60%) | #fff | Input backgrounds |
| Secondary (30%) | #c5d0e0 | Input borders |
| Accent (10%) | #6364ff | Mastodon submit hover border (neutral until Phase 122) |
| Destructive | flash-alert existing | Validation errors only |

Accent reserved for: Mastodon submit hover border only

---

## Layout & Interaction

- Instance form sits **below** existing OAuth button row inside `_oauth_buttons.html.erb`
- Stacked layout: label → text input → full-width submit
- Input: single-line hostname only; placeholder `mastodon.social` (no scheme)
- Submit uses `auth-oauth-btn` base classes; neutral styling until Phase 122 branding
- `data-turbo="false"` on form POST (match other OAuth buttons)
- Visible on sign-in and sign-up in all environments

---

## Copywriting Contract

| Element | EN | JA |
|---------|----|----|
| Instance label | Mastodon instance | Mastodonインスタンス |
| Placeholder | mastodon.social | mastodon.social |
| Submit CTA | Sign in with Mastodon | Mastodonでサインイン |
| Blank error | Enter your Mastodon instance domain. | Mastodonインスタンスのドメインを入力してください。 |
| Invalid error | Enter a valid instance domain (e.g. mastodon.social). | 有効なインスタンスのドメインを入力してください（例: mastodon.social）。 |

---

## Registry Safety

| Registry | Blocks Used | Safety Gate |
|----------|-------------|-------------|
| n/a | n/a | not required |

---

## Checker Sign-Off

- [x] Dimension 1 Copywriting: PASS
- [x] Dimension 2 Visuals: PASS
- [x] Dimension 3 Color: PASS
- [x] Dimension 4 Typography: PASS
- [x] Dimension 5 Spacing: PASS
- [x] Dimension 6 Registry Safety: PASS

**Approval:** approved 2026-06-12
