---
status: complete
quick_id: 260921-opa
description: 閲覧履歴でXもサポート
commit: 907ccc6
---

# Summary: 閲覧履歴でXもサポート

Extended v1.37.1 reading history to include X gadget link clicks.

## Changes

- `VisitedLink::HISTORY_SOURCES` (`feed`, `x`) drives `record!` title persistence and `feed_history_for` scope
- `VisitedLinksController#create` accepts `source=x`
- `visited_links.js` detects `x_account_` gadget id prefix and posts title + source
- Tests added/updated for model, controller, JS contract, and history index

## Verification

- `bin/rails test test/models/visited_link_test.rb test/controllers/visited_links_controller_test.rb test/assets/visited_links_js_contract_test.rb test/controllers/feed_article_histories_controller_test.rb` — 52 runs, 0 failures

## Commit

907ccc6 — Add X gadget visits to reading history alongside feed articles.
