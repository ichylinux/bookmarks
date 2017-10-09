require 'test_helper'

class BookmarksControllerTest < ActionDispatch::IntegrationTest

  def test_一覧
    sign_in user
    get bookmarks_path
    assert_response :success
    assert_equal '/bookmarks', path
  end

  def test_参照
    bookmark = bookmark(user)
    sign_in user

    get bookmark_path(bookmark(user))
    assert_response :success
    assert_equal "/bookmarks/#{bookmark.id}", path
  end

  def test_新規
    sign_in user
    get new_bookmark_path
    assert_response :success
    assert_equal '/bookmarks/new', path
  end

  def test_登録
    sign_in user
    post bookmarks_path, :params => {:bookmark => valid_bookmark_params(user)}
    assert_response :redirect
  end

  def test_編集
    bookmark = bookmark(user)
    sign_in user

    get edit_bookmark_path(bookmark)
    assert_response :success
    assert_equal "/bookmarks/#{bookmark.id}/edit", path
  end

  def test_更新
    bookmark = bookmark(user)
    sign_in user

    patch bookmark_path(bookmark), :params => {:bookmark => valid_bookmark_params(user)}
    assert_response :redirect
    assert_equal "/bookmarks/#{bookmark.id}", path
  end

  def test_削除
    bookmark = bookmark(user)
    sign_in user

    assert_difference 'Bookmark.not_deleted.count', -1 do
      delete bookmark_path(bookmark)
    end
    assert_response :redirect
  end
end
