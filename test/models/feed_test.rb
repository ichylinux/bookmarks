require 'test_helper'

class FeedTest < ActiveSupport::TestCase

  def test_他人のフィードは参照できない
    assert user = User.find(2)
    assert feed = Feed.where('user_id <> ?', user).first
    assert ! feed.readable_by?(user)
    assert ! feed.creatable_by?(user)
    assert ! feed.updatable_by?(user)
    assert ! feed.deletable_by?(user)
  end

end
