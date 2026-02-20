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
    post bookmarks_path, params: { bookmark: bookmark_params(user) }
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

    patch bookmark_path(bookmark), params: { bookmark: bookmark_params(user) }
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

  def test_他人のブックマークは参照できない
    sign_in user
    assert other_bookmark = Bookmark.where('user_id <> ?', user).first

    get bookmark_path(other_bookmark)
    assert_response :not_found
  end

  def test_他人のブックマークは編集できない
    sign_in user
    assert other_bookmark = Bookmark.where('user_id <> ?', user).first

    get edit_bookmark_path(other_bookmark)
    assert_response :not_found
  end

  def test_他人のブックマークは更新できない
    sign_in user
    assert other_bookmark = Bookmark.where('user_id <> ?', user).first

    patch bookmark_path(other_bookmark), params: { bookmark: bookmark_params(user) }
    assert_response :not_found
  end

  def test_他人のブックマークは削除できない
    sign_in user
    assert other_bookmark = Bookmark.where('user_id <> ?', user).first

    assert_no_difference 'Bookmark.not_deleted.count' do
      delete bookmark_path(other_bookmark)
    end
    assert_response :not_found
  end

  def test_ルートにいる場合のパンくず表示
    sign_in user
    get bookmarks_path

    assert_response :success
    assert_select 'nav.breadcrumbs', count: 1
    assert_select 'nav.breadcrumbs ol.breadcrumbs-list', count: 1
    assert_select 'a.breadcrumbs-link', text: 'ルート'
    assert_select 'a.breadcrumbs-create-folder', count: 1
    assert_select 'a.breadcrumbs-create-bookmark', count: 1
    assert_select '.breadcrumbs-label', text: 'フォルダ'
    assert_select '.breadcrumbs-label', text: 'ブックマーク'
  end

  def test_ルートにいる場合のフォルダ作成ボタンのリンク
    sign_in user
    get bookmarks_path

    assert_response :success
    assert_select 'a.breadcrumbs-create-folder[href=?]', new_bookmark_path(parent_id: nil)
    assert_select 'a.breadcrumbs-create-folder[title=?]', 'フォルダを作成'
  end

  def test_ルートにいる場合のブックマーク追加ボタンのリンク
    sign_in user
    get bookmarks_path

    assert_response :success
    assert_select 'a.breadcrumbs-create-bookmark[href=?]', new_bookmark_path(parent_id: nil)
    assert_select 'a.breadcrumbs-create-bookmark[title=?]', 'ブックマークを追加'
  end

  def test_フォルダ内にいる場合のパンくず表示
    sign_in user
    folder = Bookmark.create!(user_id: user.id, title: 'テストフォルダ', url: nil, parent_id: nil, deleted: false)
    get bookmarks_path(parent_id: folder.id)

    assert_response :success
    assert_select 'nav.breadcrumbs', count: 1
    assert_select 'nav.breadcrumbs ol.breadcrumbs-list', count: 1
    assert_select 'a.breadcrumbs-link', text: 'ルート'
    assert_select '.breadcrumbs-current', text: folder.title
    assert_select 'a.breadcrumbs-create-folder', count: 0
    assert_select 'a.breadcrumbs-create-bookmark', count: 1
    assert_select '.breadcrumbs-label', text: 'ブックマーク'
  end

  def test_フォルダ内にいる場合のブックマーク追加ボタンのリンク
    sign_in user
    folder = Bookmark.create!(user_id: user.id, title: 'テストフォルダ', url: nil, parent_id: nil, deleted: false)
    get bookmarks_path(parent_id: folder.id)

    assert_response :success
    assert_select 'a.breadcrumbs-create-bookmark[href=?]', new_bookmark_path(parent_id: folder.id)
    assert_select 'a.breadcrumbs-create-bookmark[title=?]', 'ブックマークを追加'
  end

  def test_パンくずのルートリンクが正しい
    sign_in user
    get bookmarks_path

    assert_response :success
    assert_select 'a.breadcrumbs-link[href=?]', bookmarks_path
  end

  def test_フォルダ内のパンくずのルートリンクが正しい
    sign_in user
    folder = Bookmark.create!(user_id: user.id, title: 'テストフォルダ', url: nil, parent_id: nil, deleted: false)
    get bookmarks_path(parent_id: folder.id)

    assert_response :success
    assert_select 'a.breadcrumbs-link[href=?]', bookmarks_path
  end
end
