require 'test_helper'

class FeedsControllerTest < ActionDispatch::IntegrationTest

  def test_一覧
    sign_in user
    get feeds_path
    assert_response :success
    assert_equal '/feeds', path
  end

  def test_一覧が日本語ロケールでフィードUIを表示しコンテンツは変わらない
    feed = feed_of(user)
    user.preference.update!(locale: 'ja')
    sign_in user
    get feeds_path

    assert_response :success
    assert_select 'html[lang=?]', 'ja'
    assert_select '.actions a', text: '追加', count: 1
    assert_select 'th', text: 'サイト名'
    assert_select 'th', text: '表示件数'
    assert_select 'th', text: 'フィードURL'
    assert_select 'th', text: '操作'
    assert_select 'td', text: feed.title
    assert_select 'div.feed_url', text: feed.feed_url
    assert_select 'a', text: '編集'
    assert_select 'a', text: '削除'
  end

  def test_一覧が英語ロケールでフィードUIを表示しコンテンツは変わらない
    feed = feed_of(user)
    user.preference.update!(locale: 'en')
    sign_in user
    get feeds_path

    assert_response :success
    assert_select 'html[lang=?]', 'en'
    assert_select '.actions a', text: 'Add', count: 1
    assert_select 'th', text: 'Site name'
    assert_select 'th', text: 'Display count'
    assert_select 'th', text: 'Feed URL'
    assert_select 'th', text: 'Actions'
    assert_select 'td', text: feed.title
    assert_select 'div.feed_url', text: feed.feed_url
    assert_select 'a', text: 'Edit'
    assert_select 'a', text: 'Delete'
  end

  def test_空の一覧が英語ロケールで翻訳される
    Feed.where(user_id: user.id).delete_all
    user.preference.update!(locale: 'en')
    sign_in user
    get feeds_path

    assert_response :success
    assert_select 'div', text: 'No feeds have been added.'
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

  def test_追加フォームが英語ロケールでJS用data属性と作成ボタンを表示する
    user.preference.update!(locale: 'en')
    sign_in user
    get new_feed_path

    assert_response :success
    assert_select '.actions a', text: 'Back to list', count: 1
    assert_select 'button[data-feed-url-required-message=?]', 'Enter the feed URL first.', count: 1
    assert_select 'button[data-feed-fetch-failed-message=?]', 'Could not fetch the feed.', count: 1
    assert_select 'button', text: 'Fetch From Feed', count: 1
    assert_select 'input[type=submit][value=?]', 'Create', count: 1
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

  def test_編集フォームが日本語ロケールでJS用data属性と更新ボタンを表示する
    feed = feed_of(user)
    user.preference.update!(locale: 'ja')
    sign_in user
    get edit_feed_path(feed)

    assert_response :success
    assert_select '.actions a', text: '一覧に戻る', count: 1
    assert_select 'button[data-feed-url-required-message=?]', 'フィードURLを先に入力してください。', count: 1
    assert_select 'button[data-feed-fetch-failed-message=?]', 'フィードを取得できませんでした。', count: 1
    assert_select 'button', text: 'フィードから取得', count: 1
    assert_select 'input[type=submit][value=?]', '更新', count: 1
  end

  def test_ウェルカムのフィード読込とエラー文言が英語ロケールでserver_rendered_data属性から供給される
    feed = feed_of(user)
    feed.update!(title: '日本語フィード 17-04')
    user.preference.update!(locale: 'en')
    sign_in user
    get root_path

    assert_response :success
    assert_select "#feed_#{feed.id}[data-fetch-failed-message=?]", 'Could not fetch the feed.', count: 1
    assert_select "#feed_#{feed.id} .title", text: feed.title, count: 1
    assert_select "#feed_#{feed.id} ol li span", text: 'Loading feed...', count: 1
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

  def test_fetch_titleでfeedが解決できない場合はokを返す
    sign_in user
    fake_feed = Struct.new(:feed?) { def feed? = false }.new(false)

    with_feed_new(fake_feed) do
      get fetch_title_feeds_path, params: { feed_url: 'https://example.com/feed.xml' }
    end

    assert_response :ok
    assert_equal '', response.body
  end

  private

  def with_feed_new(fake_feed)
    singleton = Feed.singleton_class
    singleton.send(:alias_method, :__feeds_test_original_new, :new)
    singleton.send(:define_method, :new) { |*_args, &_block| fake_feed }
    yield
  ensure
    singleton.send(:alias_method, :new, :__feeds_test_original_new)
    singleton.send(:remove_method, :__feeds_test_original_new)
  end

end
