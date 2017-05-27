class TweetGadget
  include Gadget

  def title
    'ツイート'
  end

  def entries
    @entries ||= Tweet.where(user_id: user.id, deleted: false).order(:tweet_id)
  end

end