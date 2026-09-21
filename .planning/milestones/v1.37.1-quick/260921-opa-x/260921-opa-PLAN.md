---
quick_id: 260921-opa
description: 閲覧履歴でXもサポート
tasks:
  - id: 1
    name: Model + controller — accept source=x and include in history scope
    files:
      - app/models/visited_link.rb
      - app/controllers/visited_links_controller.rb
    action: Add HISTORY_SOURCES %w[feed x]; extend record! and feed_history_for; controller passes x source through
    verify: bin/rails test test/models/visited_link_test.rb test/controllers/visited_links_controller_test.rb
    done: X visits persist title+source=x; history scope returns feed and x rows, not mastodon
  - id: 2
    name: JS + contract tests — x_account_ gadget posts title and source x
    files:
      - app/assets/javascripts/visited_links.js
      - test/assets/visited_links_js_contract_test.rb
      - test/controllers/feed_article_histories_controller_test.rb
    action: Detect x_account_ gadget id prefix; add/adjust tests for X history display and JS contract
    verify: bin/rails test test/assets/visited_links_js_contract_test.rb test/controllers/feed_article_histories_controller_test.rb
    done: X gadget clicks post source x; history page shows X titles; mastodon still excluded
---

# Quick Plan: 閲覧履歴でXもサポート

Extend v1.37.1 feed-only reading history to also record and display X gadget link clicks (`source='x'`), using the same title+upsert pattern as feed. Mastodon remains URL-only and excluded from the history page.
