# Feature Landscape - Guest Entry Routing

**Domain:** Acquisition entry routing for unauthenticated users  
**Researched:** 2026-05-08

## Table Stakes

| Feature | Why Expected | Complexity | Notes |
|---|---|---:|---|
| Guest root redirect | New visitors should see acquisition landing first | Low | `/` for guests -> `/landing` |
| Signed-in dashboard continuity | Existing users must keep current home behavior | Medium | No regression in gadgets/tab behavior |
| Landing CTA continuity | Conversion flow must stay visible | Low | Keep sign-up/sign-in CTA links |
| Locale-safe entry behavior | ja/en parity must hold | Medium | Redirect/render contract in both locales |

## Differentiators (Optional, not required now)
| Feature | Value | Complexity | Notes |
|---|---|---:|---|
| Temporary redirect notice for guests | Explains why URL changes | Low | Optional UX polish |
| Redirect analytics event | Conversion measurement | Medium | Requires analytics policy decision |

## Deferred to Future Milestones
- Existing-user news surface (`NEWS-01`, `NEWS-02`)
- Permanent product decision on fully replacing `/` after evaluation

## Acceptance Candidates
- Guest `GET /` redirects to `/landing`.
- Signed-in `GET /` still renders dashboard contracts.
- `GET /landing` remains public and renders CTA links.
- Entry behavior works under Japanese and English locale contexts.
