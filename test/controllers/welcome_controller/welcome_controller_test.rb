require 'test_helper'

class WelcomeController::WelcomeControllerTest < ActionDispatch::IntegrationTest

  def test_トップページ
    sign_in user
    get root_path
    assert_response :success
    assert_equal '/', path
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

  def test_ダッシュボードが日本語ロケールで固定ガジェット名を翻訳しレコード名は変えない
    feed = feed_of(user)
    feed.update!(title: '日本語フィード 17-05')
    user.preference.update!(locale: 'ja', use_calendar: true)
    sign_in user
    get root_path

    assert_response :success
    assert_select 'html[lang=?]', 'ja'
    assert_select '#bookmark_gadget .title', text: 'ブックマーク', count: 1
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
    assert_select '#bookmark_gadget .title', text: 'Bookmarks', count: 1
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
    assert_select '#todo .title', text: 'タスク', count: 1
    assert_select '#todo .todo_actions a', text: '完了', count: 1
    assert_select '#todo .todo_actions a', text: 'タスクを追加', count: 1
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
    assert_select '#todo .title', text: 'Tasks', count: 1
    assert_select '#todo .todo_actions a', text: 'Complete', count: 1
    assert_select '#todo .todo_actions a', text: 'Add Task', count: 1
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
  end

  def test_シンプルテーマで不正なtabクエリはホームを表示する
    user.preference.update!(theme: 'simple', use_note: true)
    sign_in user
    get root_path(tab: 'evil')
    assert_response :success
    assert_select '#simple-home-panel.simple-tab-panel--hidden', count: 0
    assert_select '#notes-tab-panel.simple-tab-panel--hidden', count: 1
  end

  def test_シンプルテーマのノートパネルにメモフォームが表示される
    user.preference.update!(theme: 'simple', use_note: true, locale: 'ja')
    sign_in user
    get root_path(tab: 'notes')
    assert_response :success
    assert_select '#notes-tab-panel .note-gadget', count: 1
    assert_select 'form.note-gadget-form[action=?][method=?]', notes_path, 'post', count: 1
    assert_select 'form.note-gadget-form textarea[name=?][aria-label=?]', 'note[body]', 'メモ', count: 1
    assert_select 'input[type=submit][value=?]', 'メモを保存', count: 1
  end

  def test_シンプルテーマでメモがないとき空状態を表示する
    Note.where(user_id: user.id).delete_all
    user.preference.update!(theme: 'simple', use_note: true, locale: 'ja')
    sign_in user
    get root_path(tab: 'notes')
    assert_response :success
    assert_select '#notes-tab-panel .note-empty', text: 'メモはまだありません', count: 1
    assert_select '#notes-tab-panel .note-list', count: 0
  end

  def test_シンプルテーマのノートパネルが英語ロケールで英語表示される
    Note.where(user_id: user.id).delete_all
    user.preference.update!(theme: 'simple', use_note: true, locale: 'en')
    sign_in user
    get root_path(tab: 'notes')
    assert_response :success
    assert_select 'html[lang=?]', 'en'
    assert_select 'form.note-gadget-form textarea[name=?][aria-label=?]', 'note[body]', 'Note', count: 1
    assert_select 'input[type=submit][value=?]', 'Save Note', count: 1
    assert_select '#notes-tab-panel .note-empty', text: 'No notes yet', count: 1
  end

  def test_シンプルテーマでメモは新しい順に表示されタイムスタンプも出る
    Note.where(user_id: user.id).delete_all
    older_time = Time.zone.local(2026, 4, 29, 9, 0)
    newer_time = Time.zone.local(2026, 4, 30, 9, 0)
    older = user.notes.create!(
      body: '古いメモ 13-02',
      created_at: older_time,
      updated_at: older_time
    )
    newer = user.notes.create!(
      body: '新しいメモ 13-02',
      created_at: newer_time,
      updated_at: newer_time
    )
    user.preference.update!(theme: 'simple', use_note: true)
    sign_in user
    get root_path(tab: 'notes')
    assert_response :success
    assert_select '#notes-tab-panel .note-list', count: 1
    assert_select '#notes-tab-panel .note-item', minimum: 2
    assert_operator response.body.index(newer.body), :<, response.body.index(older.body),
                    'newer note should render before older note'
    assert_includes response.body, newer_time.strftime('%Y-%m-%d %H:%M')
    assert_includes response.body, older_time.strftime('%Y-%m-%d %H:%M')
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
  end

  def test_クラシックテーマで不正なtabクエリはホームを表示する
    user.preference.update!(theme: 'classic', use_note: true)
    sign_in user
    get root_path(tab: 'evil')
    assert_response :success
    assert_select '#welcome-home-panel.welcome-tab-panel--hidden', count: 0
    assert_select '#notes-tab-panel.welcome-tab-panel--hidden', count: 1
  end

  def test_モダンテーマのノートパネルが日本語ロケールで表示される
    Note.where(user_id: user.id).delete_all
    user.preference.update!(theme: 'modern', use_note: true, locale: 'ja')
    sign_in user
    get root_path(tab: 'notes')
    assert_response :success
    assert_select 'form.note-gadget-form textarea[name=?][aria-label=?]', 'note[body]', 'メモ', count: 1
    assert_select 'input[type=submit][value=?]', 'メモを保存', count: 1
    assert_select '#notes-tab-panel .note-empty', text: 'メモはまだありません', count: 1
  end

  def test_モダンテーマのノートパネルが英語ロケールで表示される
    Note.where(user_id: user.id).delete_all
    user.preference.update!(theme: 'modern', use_note: true, locale: 'en')
    sign_in user
    get root_path(tab: 'notes')
    assert_response :success
    assert_select 'html[lang=?]', 'en'
    assert_select 'form.note-gadget-form textarea[name=?][aria-label=?]', 'note[body]', 'Note', count: 1
    assert_select 'input[type=submit][value=?]', 'Save Note', count: 1
    assert_select '#notes-tab-panel .note-empty', text: 'No notes yet', count: 1
  end

  def test_クラシックテーマのノートパネルが日本語ロケールで表示される
    Note.where(user_id: user.id).delete_all
    user.preference.update!(theme: 'classic', use_note: true, locale: 'ja')
    sign_in user
    get root_path(tab: 'notes')
    assert_response :success
    assert_select 'html[lang=?]', 'ja'
    assert_select 'form.note-gadget-form textarea[name=?][aria-label=?]', 'note[body]', 'メモ', count: 1
    assert_select 'input[type=submit][value=?]', 'メモを保存', count: 1
    assert_select '#notes-tab-panel .note-empty', text: 'メモはまだありません', count: 1
  end

  def test_クラシックテーマのノートパネルが英語ロケールで表示される
    Note.where(user_id: user.id).delete_all
    user.preference.update!(theme: 'classic', use_note: true, locale: 'en')
    sign_in user
    get root_path(tab: 'notes')
    assert_response :success
    assert_select 'html[lang=?]', 'en'
    assert_select 'form.note-gadget-form textarea[name=?][aria-label=?]', 'note[body]', 'Note', count: 1
    assert_select 'input[type=submit][value=?]', 'Save Note', count: 1
    assert_select '#notes-tab-panel .note-empty', text: 'No notes yet', count: 1
  end

  def test_ノートパネルには他ユーザーのメモが表示されない
    Note.where(user_id: user.id).delete_all
    other_user = User.find(2)
    other_user.notes.create!(
      body: '他ユーザーの秘密メモ 13-02',
      created_at: Time.zone.local(2026, 4, 30, 10, 0),
      updated_at: Time.zone.local(2026, 4, 30, 10, 0)
    )
    own_note = user.notes.create!(
      body: '自分のメモ 13-02',
      created_at: Time.zone.local(2026, 4, 30, 11, 0),
      updated_at: Time.zone.local(2026, 4, 30, 11, 0)
    )
    user.preference.update!(theme: 'simple', use_note: true, locale: 'en')
    sign_in user
    get root_path(tab: 'notes')
    assert_response :success
    assert_select 'html[lang=?]', 'en'
    assert_includes response.body, own_note.body
    assert_not_includes response.body, '他ユーザーの秘密メモ 13-02'
  end

end
