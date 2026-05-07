# Architecture - Auth-state Entry Routing

**Domain:** Rails entry-point control for guest vs signed-in users  
**Researched:** 2026-05-08

## Integration Goal
Unauthenticated users land on `/landing`, authenticated users keep `WelcomeController#index` at `/`.

## Components

### Modified
| File | Layer | Change |
|---|---|---|
| `config/routes.rb` | Routing | Keep single root endpoint while supporting auth-aware behavior |
| `app/controllers/welcome_controller.rb` (or auth gate point) | Controller | Branch guest traffic to `landing_path`; preserve signed-in path |
| `test/controllers/welcome_controller/...` | Tests | Assert guest redirect and signed-in continuity |
| `test/controllers/landing_controller_test.rb` | Tests | Assert landing + CTA + locale contracts remain valid |

### Reused
| File | Layer | Role |
|---|---|---|
| `app/controllers/landing_controller.rb` | Controller | Public landing rendering |
| `app/views/landing/show.html.erb` | View | Acquisition messaging and CTAs |

## Build Order
1. Add/adjust auth-state routing logic for `/`.
2. Keep signed-in dashboard behavior unchanged.
3. Expand route/controller tests for guest redirect and locale contracts.
4. Run tri-suite verification.

## Key Architectural Constraint
Do not introduce client-side routing; keep all behavior in Rails route/controller contracts.
