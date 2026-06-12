---
phase: 120-instance-selection-ui
plan: 01
status: complete
requirements:
  - INST-01
  - INST-02
---

# Plan 120-01 Summary

## Delivered

- `MastodonInstanceNormalizer` — strips scheme/@/slashes, validates hostname, rejects IPs and paths
- `Users::MastodonInstancesController#create` — sets `session[:mastodon_instance]`, clears stale OAuth credentials, redirects to Mastodon OmniAuth
- Route `POST /users/mastodon_instance`
- ja/en locale keys under `devise.shared.omniauth.mastodon`
- Minitest: normalizer + controller

## Key files

- `app/services/mastodon_instance_normalizer.rb`
- `app/controllers/users/mastodon_instances_controller.rb`
- `test/services/mastodon_instance_normalizer_test.rb`
- `test/controllers/users/mastodon_instances_controller_test.rb`

## Self-Check: PASSED
