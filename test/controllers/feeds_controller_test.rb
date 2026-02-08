require 'test_helper'

class FeedsControllerTest < ActionDispatch::IntegrationTest

  def test_一覧
    sign_in user
    get feeds_path
    assert_response :success
    assert_equal '/feeds', path
  end

  def test_他人のフィードは参照できない
    sign_in user
    assert feed = Feed.where('user_id <> ?', user).first

    get feed_path(feed)
    assert_response :not_found
  end

  def test_追加
    sign_in user
    get new_feed_path
    assert_response :success
    assert_equal '/feeds/new', path
  end

  def test_登録
    sign_in user
    post feeds_path, params: { feed: feed_params }
    assert_response :redirect
  end

  def test_編集
    assert feed = feed_of(user)

    sign_in user
    get edit_feed_path(feed)
    assert_response :success
    assert_equal "/feeds/#{feed.id}/edit", path
  end

  def test_更新
    assert feed = feed_of(user)

    sign_in user
    patch feed_path(feed), params: { feed: feed_params }
    assert_response :redirect
  end

  def test_他人のフィードは編集できない
    sign_in user
    assert feed = Feed.where('user_id <> ?', user).first

    get edit_feed_path(feed)
    assert_response :not_found
  end

  def test_他人のフィードは更新できない
    sign_in user
    assert feed = Feed.where('user_id <> ?', user).first

    patch feed_path(feed), params: { feed: feed_params }
    assert_response :not_found
  end

  def test_他人のフィードは削除できない
    sign_in user
    assert feed = Feed.where('user_id <> ?', user).first

    assert_no_difference 'Feed.not_deleted.count' do
      delete feed_path(feed)
    end
    assert_response :not_found
  end

end
