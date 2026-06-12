---
phase: 122
slug: auth-ui-connected-accounts
status: approved
shadcn_initialized: false
preset: none
created: 2026-06-12
---

# Phase 122 — UI Design Contract

> Visual and interaction contract for Mastodon branded auth button and Connected Accounts row.

---

## Design System

| Property | Value |
|----------|-------|
| Tool | none (Rails ERB + existing devise.css.scss / preferences styles) |
| Preset | auth-flow + connected-accounts existing |
| Component library | none |
| Icon library | inline SVG (Mastodon brand mark) |
| Font | inherit from auth-flow / preferences |

---

## Spacing Scale

| Token | Value | Usage |
|-------|-------|-------|
| xs | 4px | Icon internal padding |
| sm | 8px | Badge gaps |
| md | 12px | Form field gaps (match Phase 120) |
| lg | 16px | Mastodon section divider margin |
| xl | 24px | Section spacing |

Exceptions: none

---

## Typography

| Role | Size | Weight | Line Height |
|------|------|--------|-------------|
| Body | 15px | 400 | 1.4 |
| Button label | 15px | 600 | 1 |
| Provider name | inherit | inherit | inherit |
| Badge | 13px | 600 | 1.3 |

---

## Color

| Role | Value | Usage |
|------|-------|-------|
| Mastodon brand | #6364ff | OAuth submit background, icon accent on preferences |
| Mastodon hover | #5556e3 | OAuth submit hover background |
| Connected badge — linked | existing green | `connected-accounts__badge--connected` |
| Connected badge — unlinked | existing gray | `connected-accounts__badge--unlinked` |
| White | #fff | OAuth button text and icon on purple background |

Accent reserved for: Mastodon OAuth submit button, Mastodon provider icon fill on preferences row

---

## Layout & Interaction

### Auth pages (`_oauth_buttons.html.erb`)
- Instance form unchanged from Phase 120 (label → input → submit)
- Submit button: full-width, left-aligned icon + centered label (match Google/X/Facebook)
- Branded purple fill with white icon and label text
- `data-turbo="false"` preserved on form

### Preferences (`_connected_accounts.html.erb`)
- New row between Facebook and Email & Password
- Left: purple Mastodon icon + localized provider name
- Right: connected/unlinked badge; disconnect `button_to` when linked (same as other OAuth rows)

---

## Copywriting Contract

| Element | EN | JA |
|---------|----|----|
| OAuth submit | Sign in with Mastodon | Mastodonでサインイン |
| Instance label | Mastodon instance | Mastodonインスタンス |
| Placeholder | mastodon.social | mastodon.social |
| Connected Accounts provider | Mastodon | Mastodon |
| Connected status | Connected | 連携済み |
| Not connected | Not connected | 未連携 |
| Disconnect | Disconnect | 連携解除 |

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
