require 'test_helper'

class CalendarsControllerTest < ActionDispatch::IntegrationTest

  def test_カレンダーがまだなければ追加に遷移
    sign_in user_without_calendar
    assert Calendar.where('user_id = ?', user_without_calendar).empty?

    get calendars_path
    assert_response :redirect
    follow_redirect!
    assert_equal '/calendars/new', path
  end

  def test_一覧はないので参照に遷移
    sign_in user
    assert calendar = Calendar.where('user_id = ?', user).first

    get calendars_path
    assert_response :redirect
    follow_redirect!
    assert_equal "/calendars/#{calendar.id}", path
  end

  def test_他人のカレンダーは参照できない
    sign_in user
    assert calendar = Calendar.where('user_id <> ?', user).first

    get calendar_path(calendar)
    assert_response :not_found   
  end

  def test_追加
    sign_in user_without_calendar
    get new_calendar_path
    assert_response :success
    assert_equal '/calendars/new', path
  end

  def test_追加フォームが英語ロケールで作成ボタンを表示する
    user_without_calendar.preference.update!(locale: 'en')
    sign_in user_without_calendar
    get new_calendar_path

    assert_response :success
    assert_select 'html[lang=?]', 'en'
    assert_select 'input[type=submit][value=?]', 'Create', count: 1
  end

  def test_登録
    sign_in user_without_calendar
    post calendars_path, params: { calendar: valid_calendar_params(user_without_calendar) }
    assert_response :redirect
  end

  def test_登録_入力エラー
    sign_in user_without_calendar
    post calendars_path, params: { calendar: invalid_calendar_params(user_without_calendar) }
    assert_response :success
    assert_equal '/calendars', path
  end

  def test_編集
    calendar = calendar(user)

    sign_in user
    get edit_calendar_path(calendar)
    assert_response :success
    assert_equal "/calendars/#{calendar.id}/edit", path
  end

  def test_編集画面が英語ロケールで固定ラベルを翻訳しカレンダータイトルは変えない
    calendar = calendar(user)
    calendar.update!(title: '日本語カレンダー 17-04')
    user.preference.update!(locale: 'en')

    sign_in user
    get edit_calendar_path(calendar)

    assert_response :success
    assert_select 'html[lang=?]', 'en'
    assert_select '.actions a', text: 'View Calendar', count: 1
    assert_select 'h1', text: 'Edit Calendar', count: 1
    assert_select 'input[name=?][value=?]', 'calendar[title]', calendar.title, count: 1
    assert_select 'input[type=submit][value=?]', 'Update', count: 1
  end

  def test_編集画面が日本語ロケールでカレンダー固有の参照actionを表示する
    calendar = calendar(user)
    calendar.update!(title: '日本語カレンダー 17-05')
    user.preference.update!(locale: 'ja')
    sign_in user

    get edit_calendar_path(calendar)

    assert_response :success
    assert_select 'html[lang=?]', 'ja'
    assert_select '.actions a', text: 'カレンダーを表示', count: 1
    assert_select 'input[name=?][value=?]', 'calendar[title]', calendar.title, count: 1
  end
  
  def test_更新
    calendar = calendar(user)
    sign_in user

    patch calendar_path(calendar), params: { calendar: valid_calendar_params(user) }
    assert_response :redirect
    follow_redirect!
    assert_equal "/calendars/#{calendar.id}", path
  end

  def test_更新_入力エラー
    calendar = calendar(user)
    sign_in user

    patch calendar_path(calendar), params: { calendar: invalid_calendar_params(user) }
    assert_response :success
    assert_equal "/calendars/#{calendar.id}", path
  end

  def test_削除
    calendar = calendar(user)
    sign_in user

    assert_difference 'Calendar.not_deleted.count', -1 do
      delete calendar_path(calendar)
    end
    assert_response :redirect
    follow_redirect!
    assert_equal '/calendars', path
  end

  def test_他人のカレンダーは編集できない
    sign_in user
    assert calendar = Calendar.where('user_id <> ?', user).first

    get edit_calendar_path(calendar)
    assert_response :not_found
  end

  def test_他人のカレンダーは更新できない
    sign_in user
    assert calendar = Calendar.where('user_id <> ?', user).first

    patch calendar_path(calendar), params: { calendar: valid_calendar_params(user) }
    assert_response :not_found
  end

  def test_他人のカレンダーは削除できない
    sign_in user
    assert calendar = Calendar.where('user_id <> ?', user).first

    assert_no_difference 'Calendar.not_deleted.count' do
      delete calendar_path(calendar)
    end
    assert_response :not_found
  end

  def test_ガジェットの取得
    calendar = calendar(user)
    sign_in user

    get get_gadget_calendar_path(calendar), params: { display_date: Date.today.strftime('%Y-%m-%d') }
    assert_response :success
    assert_equal "/calendars/#{calendar.id}/get_gadget", path
  end

  def test_ガジェットが日本語ロケールで月_曜日_ナビラベルを表示し祝日名はそのまま
    calendar = calendar(user)
    user.preference.update!(locale: 'ja')
    sign_in user

    get get_gadget_calendar_path(calendar), params: { display_date: '2026-01-01' }

    assert_response :success
    assert_select 'caption span', text: '2026年1月', count: 1
    assert_select 'caption a[aria-label=?][title=?]', '前の月', '前の月', text: '<<', count: 1
    assert_select 'caption a[aria-label=?][title=?]', '次の月', '次の月', text: '>>', count: 1
    assert_select 'th.sunday', text: '日', count: 1
    assert_select 'th', text: '木', count: 1
    assert_includes response.body, '元日'
  end

  def test_ガジェットが英語ロケールで月_曜日_ナビラベルを表示し祝日名はそのまま
    calendar = calendar(user)
    user.preference.update!(locale: 'en')
    sign_in user

    get get_gadget_calendar_path(calendar), params: { display_date: '2026-01-01' }

    assert_response :success
    assert_select 'caption span', text: 'January 2026', count: 1
    assert_select 'caption a[aria-label=?][title=?]', 'Previous month', 'Previous month', text: '<<', count: 1
    assert_select 'caption a[aria-label=?][title=?]', 'Next month', 'Next month', text: '>>', count: 1
    assert_select 'th.sunday', text: 'Sun', count: 1
    assert_select 'th', text: 'Thu', count: 1
    assert_includes response.body, '元日'
  end

  def test_参照画面が英語ロケールでactionを翻訳しカレンダータイトルは変えない
    calendar = calendar(user)
    calendar.update!(title: '日本語カレンダー 17-04')
    user.preference.update!(locale: 'en')
    sign_in user

    get calendar_path(calendar)

    assert_response :success
    assert_select '.actions a', text: 'Edit', count: 1
    assert_select '.actions a', text: 'Delete', count: 1
    assert_select 'td', text: calendar.title, count: 1
  end

  def test_ウェルカムのカレンダー読込文言が英語ロケールでタイトルを保持して翻訳される
    calendar = calendar(user)
    calendar.update!(title: '日本語カレンダー 17-04')
    user.preference.update!(locale: 'en')
    sign_in user

    get root_path

    assert_response :success
    assert_select "#calendar_#{calendar.id} .title", text: calendar.title, count: 1
    assert_select "#calendar_#{calendar.id} span", text: "Loading #{calendar.title}...", count: 1
  end
end
