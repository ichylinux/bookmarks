class BackfillXAndMastodonVisitedLinkSources < ActiveRecord::Migration[8.1]
  def up
    VisitedLink.backfill_history_sources!
  end

  def down
    VisitedLink.where(source: %w[x mastodon], title: nil).update_all(source: nil)
  end
end
