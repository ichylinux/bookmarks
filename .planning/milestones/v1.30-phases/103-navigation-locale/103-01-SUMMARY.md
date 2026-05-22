---
phase: 103-navigation-locale
plan: 01
status: complete
completed_at: "2026-05-21"
commit: 5f53310
---

# Summary: Navigation, Locale & Tri-suite Gate

## What was built

- `app/views/common/_nav_sections.html.erb` — added `admin_users_path` nav item before `admin_x_api_usages_path` in the admin section
- `config/locales/ja.yml` + `en.yml` — `nav.users` + `admin.users.index.{title,col_id,col_email,col_x_user_name,col_admin_flag,col_last_sign_in_at,col_created_at,col_updated_at}` (9 new keys each)
- `app/views/admin/users/index.html.erb` — heading and all column headers use `t('.title')` / `t('.col_*')`
- `test/i18n/admin_users_i18n_test.rb` — 2 parity tests (ja + en), all 9 keys
- `features/11.Admin.feature` — Cucumber scenario: admin navigates to `/admin/users`, sees table
- `features/step_definitions/admin_users.rb` — 2 step definitions
- `test/controllers/welcome_controller/layout_structure_test.rb` — updated admin link counts (1→2)

## Verification

- `bin/rails test test/i18n/admin_users_i18n_test.rb` → 2 runs, 0 failures ✓
- `yarn run lint` ✓
- `bin/rails test` → 528 runs, 0 failures ✓
- `bundle exec rake dad:test` → 31 scenarios, 31 passed ✓
