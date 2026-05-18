class XAccountsController < ApplicationController
  include TwitterLinkRequirement

  before_action :require_twitter_linked
  before_action :preload_account, only: %w[show update]
  before_action :assign_visited_urls, only: [:show]

  def index
    @x_accounts = XAccount.where(user_id: current_user.id).not_deleted.order(:username)
    @selected_count = XAccount.selected_count_for(current_user)
    @selection_soft_warning = @selected_count >= XAccount::SOFT_WARNING_AT && @selected_count < XAccount::MAX_SELECTION
  end

  def refresh
    result = XClient.new.fetch_following(user: current_user)
    unless result[:success]
      flash[:alert] = t("errors.x_client.#{result[:error]}")
      redirect_to x_accounts_path and return
    end

    XAccount.refresh_cache_from_items!(current_user, result[:items])
    flash[:notice] = t('x_accounts.refresh.success')
    redirect_to x_accounts_path
  end

  def show
    result = XClient.new.fetch_recent_tweets(
      user: current_user,
      x_user_id: @x_account.x_user_id,
      limit: @x_account.display_count
    )

    if result[:success]
      @x_items = result[:items]
      @x_error = nil
    else
      @x_items = []
      @x_error = result[:error]
    end

    render layout: !request.xhr?
  end

  def update
    @x_account.attributes = x_account_params

    @x_account.transaction do
      @x_account.save!
    end

    redirect_to x_accounts_path, notice: t('x_accounts.update.success')
  rescue ActiveRecord::RecordInvalid
    msg = @x_account.errors[:selected].presence ||
          @x_account.errors.full_messages.presence ||
          t('x_accounts.update.failure')
    redirect_to x_accounts_path, alert: msg
  end

  private

  def preload_account
    @x_account = XAccount.find(params[:id])

    unless @x_account.readable_by?(current_user)
      head :not_found and return
    end

    head :not_found and return if @x_account.deleted?
  end

  def assign_visited_urls
    @visited_urls = VisitedLink.urls_for(current_user)
  end

  def x_account_params
    params.require(:x_account).permit(:selected, :protected_acknowledged, :display_count)
  end
end
