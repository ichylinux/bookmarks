---
created: 2026-05-19T09:50:09Z
title: Investigate X API Bearer Token vs OAuth 1.0a
area: api
files:
  - app/services/x_client.rb:88-97
---

## Problem

`XClient` currently authenticates with X API v2 using **OAuth 1.0a User Context** (via `faraday/oauth1` with per-user `token` + `token_secret`). This approach ties every request to individual user credentials.

Bearer Token (OAuth 2.0 App-Only) is simpler — one token for the whole app — but is limited to public, read-only data and cannot act on behalf of a user (no likes, bookmarks from the user's account, etc.).

Question: for the read operations this app actually performs (fetching bookmarks/tweets on behalf of a user), which auth method does the X API v2 actually require? Is OAuth 1.0a genuinely necessary, or could Bearer Token + user-level scoped token work?

## Solution

1. Audit what API endpoints `XClient` calls and what auth scopes they require.
2. Check X API v2 docs: does the bookmarks endpoint (`/2/users/:id/bookmarks`) require OAuth 1.0a User Context or OAuth 2.0 with user token?
3. If Bearer Token (App-Only) is insufficient for user bookmarks, the current approach is correct. If OAuth 2.0 with PKCE user token is sufficient, consider migrating off `faraday/oauth1`.
4. Document decision as an ADR regardless of outcome.
