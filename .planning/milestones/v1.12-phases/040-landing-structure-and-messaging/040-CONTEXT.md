# Phase 40: Landing Structure and Messaging - Context

**Gathered:** 2026-05-08
**Status:** Ready for planning

<domain>
## Phase Boundary

Create a new public `/landing` page for first-time visitors with clear value messaging while keeping the existing `/` behavior unchanged.

</domain>

<decisions>
## Implementation Decisions

- Keep `root_path` on `welcome#index` (no replacement in this milestone).
- Expose landing as a separate public entry point (`/landing`).
- Messaging must stay user-experience focused and avoid implementation details.
- Add ja/en localization keys for all landing copy from the start.

</decisions>

<specifics>
## Specific Ideas

- Add `LandingController#show` with `skip_before_action :authenticate_user!`.
- Render hero + value cards + primary/secondary CTA links.
- Add dedicated landing stylesheet and keep style scope local to landing classes.

</specifics>

---

*Phase: 040-landing-structure-and-messaging*
*Context gathered: 2026-05-08*
