class FeedArticleHistoriesController < ApplicationController
  def index
    head :not_found and return unless current_user.preference.use_feed_article_histories?

    page = [params[:page].to_i, 1].max
    @feed_article_histories = VisitedLink.feed_history_for(current_user).page(page)
    @gadget_titles = VisitedLink.gadget_titles_for(
      current_user,
      @feed_article_histories.map(&:gadget_id).compact
    )
  end
end
