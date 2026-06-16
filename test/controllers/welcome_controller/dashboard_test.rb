require 'test_helper'

class WelcomeController::DashboardTest < ActionDispatch::IntegrationTest

  def test_トップページ
    sign_in user
    get root_path
    assert_response :success
    assert_equal '/', path
  end

  def test_VisitedLinkに記録済みでもブックマークリンクにlink__visitedが付かない
    sign_in user
    VisitedLink.record!(user, 'www.example.com')
    get root_path
    assert_response :success
    assert_select '#bookmark_gadget a[href=?]', 'www.example.com', text: 'ブックマーク1'
    assert_select '#bookmark_gadget a.link--visited', count: 0
  end

  def test_ブックマークを新しいタブで開く設定がオンのときリンクにtarget_blankが付く
    sign_in user
    user.preference.update!(open_links_in_new_tab: true)
    get root_path
    assert_response :success
    assert_select '#bookmark_gadget a[href=?][target=?][rel=?]', 'www.example.com', '_blank', 'noopener noreferrer', text: 'ブックマーク1'
  end

  def test_ブックマークを新しいタブで開く設定がオフのときリンクにtarget_blankが付かない
    sign_in user
    user.preference.update!(open_links_in_new_tab: false)
    get root_path
    assert_response :success
    assert_select '#bookmark_gadget a[href=?]', 'www.example.com', text: 'ブックマーク1'
    assert_select '#bookmark_gadget a[href=?][target=?]', 'www.example.com', '_blank', count: 0
  end

  def test_use_calendarがオフのときカレンダーガジェットを表示しない
    user.preference.update!(use_calendar: false)
    sign_in user
    get root_path
    assert_response :success
    assert_select '#calendar', count: 0
  end

  def test_ブックマーク追加ダイアログフォームがAJAX送信とガジェットURLを持つ
    sign_in user
    get root_path
    assert_response :success
    assert_select 'form.bookmark-new-dialog__form[action=?][data-remote=?][data-gadget-url=?]',
                  bookmarks_path, 'true', gadget_bookmarks_path,
                  count: 1
  end

  def test_ダッシュボードが日本語ロケールで固定ガジェット名を翻訳しレコード名は変えない
    feed = feed_of(user)
    feed.update!(title: '日本語フィード 17-05')
    user.preference.update!(locale: 'ja', use_calendar: true)
    sign_in user
    get root_path

    assert_response :success
    assert_select 'html[lang=?]', 'ja'
    assert_select '#bookmark_gadget .gadget-title-text', text: 'ブックマーク', count: 1
    assert_select '#bookmark_gadget a', text: 'ブックマーク1'
    assert_select "#feed_#{feed.id} .title", text: feed.title, count: 1
    assert_select '#calendar .title', text: 'カレンダー', count: 1
  end

  def test_ダッシュボードが英語ロケールで固定ガジェット名を翻訳しレコード名は変えない
    feed = feed_of(user)
    feed.update!(title: '日本語フィード 17-05')
    user.preference.update!(locale: 'en', use_calendar: true)
    sign_in user
    get root_path

    assert_response :success
    assert_select 'html[lang=?]', 'en'
    assert_select '#bookmark_gadget .gadget-title-text', text: 'Bookmarks', count: 1
    assert_select '#bookmark_gadget a', text: 'ブックマーク1'
    assert_select "#feed_#{feed.id} .title", text: feed.title, count: 1
    assert_select '#calendar .title', text: 'Calendar', count: 1
  end

  def test_Todoガジェットが日本語ロケールで日本語表示される
    todo = Todo.where(user_id: user.id).first
    todo.update!(priority: Todo::PRIORITY_HIGH)
    user.preference.update!(use_todo: true, locale: 'ja')
    sign_in user
    get root_path

    assert_response :success
    assert_select '#todo .gadget-title-text', text: 'タスク', count: 1
    assert_select '#todo ol[data-complete-url][data-undo-url]', count: 1
    assert_select '#todo .title a.todo-gadget-new-link', text: '追加', count: 1
    assert_select '#todo span.priority_1', text: '高', count: 1
  end

  def test_Todoガジェットが英語ロケールで英語表示されタイトルは変わらない
    todo = Todo.where(user_id: user.id).first
    todo.update!(title: '日本語タスク 17-03', priority: Todo::PRIORITY_HIGH)
    user.preference.update!(use_todo: true, locale: 'en')
    sign_in user
    get root_path

    assert_response :success
    assert_select 'html[lang=?]', 'en'
    assert_select '#todo .gadget-title-text', text: 'Tasks', count: 1
    assert_select '#todo ol[data-complete-url][data-undo-url]', count: 1
    assert_select '#todo .title a.todo-gadget-new-link', text: 'new', count: 1
    assert_select '#todo span.priority_1', text: 'High', count: 1
    assert_includes response.body, todo.title
  end

  def test_シンプルテーマでuse_noteがfalseのときノートパネルが表示されない
    user.preference.update!(theme: 'simple', use_note: false)
    sign_in user
    get root_path
    assert_response :success
    assert_select '#simple-home-panel', count: 1
    assert_select '#notes-tab-panel', count: 0
  end

  def test_シンプルテーマでウェルカムにホームとノートのパネルが表示される
    user.preference.update!(theme: 'simple', use_note: true)
    sign_in user
    get root_path
    assert_response :success
    assert_select '#simple-home-panel', count: 1
    assert_select '#notes-tab-panel', count: 1
  end

  def test_シンプルテーマでtab_notesクエリのときノートパネルが非表示クラスでホームが隠される
    user.preference.update!(theme: 'simple', use_note: true)
    sign_in user
    get root_path(tab: 'notes')
    assert_response :success
    assert_select '#simple-home-panel.simple-tab-panel--hidden', count: 1
    assert_select '#notes-tab-panel.simple-tab-panel--hidden', count: 0
    assert_select '#notes-tab-panel .note-gadget-loading', count: 1
  end

  def test_シンプルテーマで不正なtabクエリはホームを表示する
    user.preference.update!(theme: 'simple', use_note: true)
    sign_in user
    get root_path(tab: 'evil')
    assert_response :success
    assert_select '#simple-home-panel.simple-tab-panel--hidden', count: 0
    assert_select '#notes-tab-panel.simple-tab-panel--hidden', count: 1
  end


  def test_モダンテーマでuse_noteがfalseのときノートパネルが表示されない
    user.preference.update!(theme: 'modern', use_note: false)
    sign_in user
    get root_path
    assert_response :success
    assert_select '#welcome-home-panel', count: 1
    assert_select '#notes-tab-panel', count: 0
  end

  def test_モダンテーマでルートではノートパネルが隠れtab_notesで表示される
    user.preference.update!(theme: 'modern', use_note: true)
    sign_in user
    get root_path
    assert_response :success
    assert_select '#welcome-home-panel.welcome-tab-panel--hidden', count: 0
    assert_select '#notes-tab-panel.welcome-tab-panel--hidden', count: 1

    get root_path(tab: 'notes')
    assert_response :success
    assert_select '#welcome-home-panel.welcome-tab-panel--hidden', count: 1
    assert_select '#notes-tab-panel.welcome-tab-panel--hidden', count: 0
    assert_select '#notes-tab-panel .note-gadget-loading', count: 1
  end

  def test_モダンテーマで不正なtabクエリはホームを表示する
    user.preference.update!(theme: 'modern', use_note: true)
    sign_in user
    get root_path(tab: 'evil')
    assert_response :success
    assert_select '#welcome-home-panel.welcome-tab-panel--hidden', count: 0
    assert_select '#notes-tab-panel.welcome-tab-panel--hidden', count: 1
  end

  def test_クラシックテーマでuse_noteがfalseのときノートパネルが表示されない
    user.preference.update!(theme: 'classic', use_note: false)
    sign_in user
    get root_path
    assert_response :success
    assert_select '#welcome-home-panel', count: 1
    assert_select '#notes-tab-panel', count: 0
  end

  def test_クラシックテーマでルートではノートパネルが隠れtab_notesで表示される
    user.preference.update!(theme: 'classic', use_note: true)
    sign_in user
    get root_path
    assert_response :success
    assert_select '#welcome-home-panel.welcome-tab-panel--hidden', count: 0
    assert_select '#notes-tab-panel.welcome-tab-panel--hidden', count: 1

    get root_path(tab: 'notes')
    assert_response :success
    assert_select '#welcome-home-panel.welcome-tab-panel--hidden', count: 1
    assert_select '#notes-tab-panel.welcome-tab-panel--hidden', count: 0
    assert_select '#notes-tab-panel .note-gadget-loading', count: 1
  end

  def test_クラシックテーマで不正なtabクエリはホームを表示する
    user.preference.update!(theme: 'classic', use_note: true)
    sign_in user
    get root_path(tab: 'evil')
    assert_response :success
    assert_select '#welcome-home-panel.welcome-tab-panel--hidden', count: 0
    assert_select '#notes-tab-panel.welcome-tab-panel--hidden', count: 1
  end

  def test_show_iconsがfalseのときbodyにno_iconsクラスが付く
    user.preference.update!(show_icons: false)
    sign_in user
    get root_path
    assert_response :success
    assert_select 'body.no-icons'
  end

  def test_show_iconsがtrueのときbodyにno_iconsクラスが付かない
    user.preference.update!(show_icons: true)
    sign_in user
    get root_path
    assert_response :success
    assert_select 'body.no-icons', count: 0
  end

  def test_indexはnoteとnotesを割り当てない
    user.preference.update!(use_note: true)
    sign_in user
    get root_path
    assert_response :success
    # @note and @notes are no longer assigned by WelcomeController#index.
    # The notes panel should contain only the loading placeholder, not a note form.
    assert_select '#notes-tab-panel form.note-gadget-form', count: 0
    assert_select '#notes-tab-panel .note-gadget-loading', count: 1
  end

end
