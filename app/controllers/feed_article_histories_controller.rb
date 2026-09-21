class FeedArticleHistoriesController < ApplicationController
  def index
    head :not_found and return unless current_user.preference.use_feed_article_histories?

    @feed_article_histories = VisitedLink.feed_history_for(current_user)
  end
end
