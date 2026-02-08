class TweetsController < ApplicationController

  def index
    @tweets = Tweet.where(user_id: current_user.id).not_deleted
  end

  def show
    @tweet = Tweet.find(params[:id])

    unless @tweet.readable_by?(current_user)
      head :not_found and return
    end
  end

  def new
    @tweet = Tweet.new
  end

  def create
    @tweet = Tweet.new(tweet_params)

    @tweet.transaction do
      @tweet.save!
    end

    redirect_to action: 'index'
  end

  def edit
    @tweet = Tweet.find(params[:id])

    unless @tweet.updatable_by?(current_user)
      head :not_found and return
    end
  end

  def update
    @tweet = Tweet.find(params[:id])

    unless @tweet.updatable_by?(current_user)
      head :not_found and return
    end

    @tweet.attributes = tweet_params

    @tweet.transaction do
      @tweet.save!
    end

    redirect_to action: 'index'
  end

  def destroy
    @tweet = Tweet.find(params[:id])

    unless @tweet.deletable_by?(current_user)
      head :not_found and return
    end

    @tweet.transaction do
      @tweet.destroy_logically!
    end

    redirect_to action: 'index'
  end

  private

  def tweet_params
    permitted = [:tweet_id]

    ret = params.require(:tweet).permit(permitted)
    ret.merge!(user_id: current_user.id)
    ret
  end

end
