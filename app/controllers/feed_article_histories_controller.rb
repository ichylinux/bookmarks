class FeedArticleHistoriesController < ApplicationController
  def index
    head :not_found and return unless current_user.preference.use_feed_article_histories?

    page = [params[:page].to_i, 1].max
    @filter_liked = ActiveModel::Type::Boolean.new.cast(params[:liked])
    scope = VisitedLink.feed_history_for(current_user)
    scope = scope.liked_only if @filter_liked
    @feed_article_histories = scope.page(page)
    @gadget_titles = VisitedLink.gadget_titles_for(
      current_user,
      @feed_article_histories.map(&:gadget_id).compact
    )
    @liked_urls = @feed_article_histories.filter_map { |link| link.url if link.liked? }.to_set
  end
end
