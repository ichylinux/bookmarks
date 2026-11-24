class MastodonAccountsController < ApplicationController
  before_action :preload_account, only: %w[show edit update destroy]

  def index
    @mastodon_accounts = MastodonAccount.where(user_id: current_user.id).not_deleted.order(:instance, :username)
  end

  def new
    @mastodon_account = MastodonAccount.new
  end

  def create
    @mastodon_account = MastodonAccount.new(mastodon_account_params)

    @mastodon_account.transaction do
      @mastodon_account.save!
    end

    redirect_to action: 'index'
  end

  def show
    result = MastodonClient.new(instance_host: @mastodon_account.instance)
      .fetch_recent_status_previews(
        username: @mastodon_account.username,
        limit: @mastodon_account.display_count
      )

    if result[:success]
      @mastodon_items = result[:items]
      @mastodon_error = nil
    else
      @mastodon_items = []
      @mastodon_error = result[:error]
    end

    assign_visited_urls
    render layout: !request.xhr?
  end

  def edit
  end

  def update
    @mastodon_account.attributes = mastodon_account_params

    @mastodon_account.transaction do
      @mastodon_account.save!
    end

    if params[:return_to] == 'dashboard'
      if request.xhr?
        head :ok
      else
        redirect_to root_path
      end
    else
      redirect_to action: 'index'
    end
  rescue ActiveRecord::RecordInvalid
    if params[:return_to] == 'dashboard' && request.xhr?
      render plain: @mastodon_account.errors.full_messages.to_sentence, status: :unprocessable_entity
    else
      raise
    end
  end

  def destroy
    @mastodon_account.transaction do
      @mastodon_account.destroy_logically!
    end

    redirect_to action: 'index'
  end

  private

  def preload_account
    @mastodon_account = MastodonAccount.find(params[:id])

    unless @mastodon_account.readable_by?(current_user)
      head :not_found and return
    end

    head :not_found and return if @mastodon_account.deleted?
  end

  def assign_visited_urls
    entry_urls = @mastodon_items.map { |item| item[:url] }
    assign_entry_link_states(entry_urls)
  end

  def mastodon_account_params
    ret = params.require(:mastodon_account).permit(:profile_url, :display_count)
    ret.merge!(user_id: current_user.id)
  end
end
