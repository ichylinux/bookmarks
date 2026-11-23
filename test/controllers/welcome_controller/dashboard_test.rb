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
    assert_select '#todo .title .todo-gadget-complete-link', text: '完了', count: 1
    assert_select '#todo .title a.todo-gadget-new-link', text: '追加', count: 1
    assert_select '#todo .todo-gadget-complete-group', count: 1
    assert_select '#todo .todo-gadget-selected-count[data-template=?]', '%{count}件選択中', count: 1
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
    assert_select '#todo .title .todo-gadget-complete-link', text: 'Complete', count: 1
    assert_select '#todo .title a.todo-gadget-new-link', text: 'new', count: 1
    assert_select '#todo .todo-gadget-complete-group', count: 1
    assert_select '#todo .todo-gadget-selected-count[data-template=?]', '%{count} selected', count: 1
    assert_select '#todo span.priority_1', text: 'High', count: 1
    assert_includes response.body, todo.title
  end

  def test_ウェルカムにノートパネルは含まれない
    user.preference.update!(theme: 'modern', use_note: true)
    sign_in user
    get root_path
    assert_response :success
    assert_select '#notes-page', count: 0
  end

  def test_tab_notesクエリはnotesページへリダイレクトする
    user.preference.update!(use_note: true)
    sign_in user
    get root_path(tab: 'notes')
    assert_redirected_to notes_path
  end

  def test_use_noteオフのときtab_notesクエリはリダイレクトしない
    user.preference.update!(use_note: false)
    sign_in user
    get root_path(tab: 'notes')
    assert_response :success
    assert_equal root_path, path
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

end
