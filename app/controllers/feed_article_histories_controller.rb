class FeedArticleHistoriesController < ApplicationController
  def index
    head :not_found and return unless current_user.preference.use_feed_article_histories?

    page = [params[:page].to_i, 1].max
    @feed_article_histories = VisitedLink.feed_history_for(current_user).page(page)
  end
end
