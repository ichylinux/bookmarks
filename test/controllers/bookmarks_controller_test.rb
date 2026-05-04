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

  def test_ブックマーク新規フォームが日本語ロケールで表示される
    user.preference.update!(locale: 'ja')
    sign_in user
    get new_bookmark_path(kind: 'bookmark')

    assert_response :success
    assert_select 'html[lang=?]', 'ja'
    assert_select 'input#bookmark_url[placeholder=?]', 'URL（フォルダの場合は空欄）'
    assert_select 'small', text: 'URLを空欄にするとフォルダとして作成されます'
    assert_select 'small', text: 'URLを入力したあと「URLから取得」でタイトルを取得できます。'
    assert_select 'label[for=bookmark_parent_id]', text: '親フォルダ'
    assert_select 'option', text: 'なし（ルート）'
    assert_select 'input[type=submit][value=?]', 'ブックマークを追加'
    assert_select 'button', text: 'URLから取得'
  end

  def test_ブックマーク新規フォームが英語ロケールで表示されフォルダ名は変わらない
    folder = Bookmark.create!(user_id: user.id, title: '日本語フォルダ17-02', url: nil, parent_id: nil, deleted: false)
    user.preference.update!(locale: 'en')
    sign_in user
    get new_bookmark_path(parent_id: folder.id, kind: 'bookmark')

    assert_response :success
    assert_select 'html[lang=?]', 'en'
    assert_select 'input#bookmark_url[placeholder=?]', 'URL (leave blank for folders)'
    assert_select 'small', text: 'Leave URL blank to create a folder'
    assert_select 'small', text: 'After entering a URL, use "Fetch from URL" to fill in the title.'
    assert_select 'label[for=bookmark_parent_id]', text: 'Parent folder'
    assert_select 'option', text: 'None (root)'
    assert_select 'option', text: folder.title
    assert_select 'input[type=submit][value=?]', 'Add Bookmark'
    assert_select 'button', text: 'Fetch from URL'
  end

  def test_フォルダ作成フォームが明示的な日本語submitを表示する
    user.preference.update!(locale: 'ja')
    sign_in user
    get new_bookmark_path(kind: 'folder')

    assert_response :success
    assert_select 'input[type=submit][value=?]', 'フォルダを作成'
    assert_select 'button', text: 'URLから取得', count: 0
  end

  def test_編集フォームが英語ロケールで更新submitを表示する
    bookmark = bookmark(user)
    user.preference.update!(locale: 'en')
    sign_in user
    get edit_bookmark_path(bookmark)

    assert_response :success
    assert_select 'h1', text: 'Edit Bookmark'
    assert_select 'input[type=submit][value=?]', 'Update'
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

  def test_一覧が英語ロケールで表示されユーザー作成内容は変わらない
    folder = Bookmark.create!(user_id: user.id, title: '日本語フォルダ17-02-index', url: nil, parent_id: nil, deleted: false)
    bookmark = Bookmark.create!(user_id: user.id, title: '日本語ブックマーク17-02-index', url: 'https://example.com/17-02', parent_id: nil, deleted: false)
    user.preference.update!(locale: 'en')
    sign_in user
    get bookmarks_path

    assert_response :success
    assert_select 'html[lang=?]', 'en'
    assert_select 'nav.breadcrumbs[aria-label=?]', 'Breadcrumbs'
    assert_select 'a.breadcrumbs-link', text: 'Root'
    assert_select 'a.breadcrumbs-create-folder[title=?]', 'Create Folder'
    assert_select 'a.breadcrumbs-create-bookmark[title=?]', 'Add Bookmark'
    assert_select '.breadcrumbs-label', text: 'Folder'
    assert_select '.breadcrumbs-label', text: 'Bookmark'
    assert_select 'th', text: 'Actions'
    assert_select 'a', text: 'Edit'
    assert_select 'a[data-confirm=?]', "Delete #{bookmark.title}. Are you sure?"
    assert_includes response.body, folder.title
    assert_includes response.body, bookmark.title
    assert_includes response.body, bookmark.url
  end

  def test_ルートにいる場合のフォルダ作成ボタンのリンク
    sign_in user
    get bookmarks_path

    assert_response :success
    assert_select 'a.breadcrumbs-create-folder[href=?]', new_bookmark_path(parent_id: nil, kind: 'folder')
    assert_select 'a.breadcrumbs-create-folder[title=?]', 'フォルダを作成'
  end

  def test_ルートにいる場合のブックマーク追加ボタンのリンク
    sign_in user
    get bookmarks_path

    assert_response :success
    assert_select 'a.breadcrumbs-create-bookmark[href=?]', new_bookmark_path(parent_id: nil, kind: 'bookmark')
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

  def test_フォルダ内一覧が英語ロケールでも親フォルダ名を変えない
    folder = Bookmark.create!(user_id: user.id, title: '日本語フォルダ17-02-parent', url: nil, parent_id: nil, deleted: false)
    user.preference.update!(locale: 'en')
    sign_in user
    get bookmarks_path(parent_id: folder.id)

    assert_response :success
    assert_select 'html[lang=?]', 'en'
    assert_select 'a.breadcrumbs-link', text: 'Root'
    assert_select '.breadcrumbs-current', text: folder.title
    assert_select 'a.breadcrumbs-create-folder', count: 0
    assert_select '.breadcrumbs-label', text: 'Bookmark'
  end

  def test_詳細が英語ロケールで表示されブックマーク内容と親フォルダ名は変わらない
    folder = Bookmark.create!(user_id: user.id, title: '日本語親フォルダ17-02', url: nil, parent_id: nil, deleted: false)
    bookmark = Bookmark.create!(user_id: user.id, title: '日本語ブックマーク17-02-show', url: 'https://example.com/show-17-02', parent_id: folder.id, deleted: false)
    user.preference.update!(locale: 'en')
    sign_in user
    get bookmark_path(bookmark)

    assert_response :success
    assert_select 'html[lang=?]', 'en'
    assert_select '.actions a', text: 'Back to list'
    assert_select '.actions a', text: 'Edit'
    assert_select 'th', text: 'Parent folder'
    assert_includes response.body, bookmark.title
    assert_includes response.body, bookmark.url
    assert_includes response.body, folder.title
  end

  def test_編集が英語ロケールで一覧リンクを翻訳する
    bookmark = bookmark(user)
    user.preference.update!(locale: 'en')
    sign_in user
    get edit_bookmark_path(bookmark)

    assert_response :success
    assert_select 'h1', text: 'Edit Bookmark'
    assert_select '.actions a', text: 'Back to list'
  end

  def test_フォルダ内にいる場合のブックマーク追加ボタンのリンク
    sign_in user
    folder = Bookmark.create!(user_id: user.id, title: 'テストフォルダ', url: nil, parent_id: nil, deleted: false)
    get bookmarks_path(parent_id: folder.id)

    assert_response :success
    assert_select 'a.breadcrumbs-create-bookmark[href=?]', new_bookmark_path(parent_id: folder.id, kind: 'bookmark')
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
