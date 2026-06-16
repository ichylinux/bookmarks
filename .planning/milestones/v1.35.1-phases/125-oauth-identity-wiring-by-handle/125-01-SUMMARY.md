# Plan 125-01 Summary

**Completed:** 2026-06-16

## Changes

- Extended `User.from_omniauth` `:mastodon` branch: composite uid lookup → handle match → create
- Handle match uses OAuth `nickname` + session `instance` via `MastodonHandleNormalizer`
- Soft-deleted users excluded via `User.active` scope
- Minitest: match, squatting rejection (instance/username), deleted user exclusion

## Files Modified

- `app/models/user.rb`
- `test/models/oauth_identity_test.rb`
