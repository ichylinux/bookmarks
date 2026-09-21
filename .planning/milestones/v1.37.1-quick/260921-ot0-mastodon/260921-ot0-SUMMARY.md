---
status: complete
quick_id: 260921-ot0
description: 閲覧履歴でMastodonもサポート
commit: 152895f
---

# Summary: 閲覧履歴でMastodonもサポート

Extended reading history to include Mastodon gadget link clicks.

## Changes

- `VisitedLink::HISTORY_SOURCES` now includes `mastodon` alongside `feed` and `x`
- `VisitedLinksController#create` accepts `source=mastodon`
- `visited_links.js` detects `mastodon_account_` gadget id prefix and posts title + source
- Tests added/updated for model, controller, JS contract, and history index

## Verification

- `yarn run lint` — green
- `bin/rails test test/models/visited_link_test.rb test/controllers/visited_links_controller_test.rb test/assets/visited_links_js_contract_test.rb test/controllers/feed_article_histories_controller_test.rb` — 56 runs, 0 failures

## Commit

152895f — Add Mastodon gadget visits to reading history alongside feed and X.
