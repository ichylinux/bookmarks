class FeedArticleHistoriesController < ApplicationController
  def index
    @feed_article_histories = VisitedLink.feed_history_for(current_user)
  end
end
