require 'test_helper'

class CalendarsControllerTest < ActionDispatch::IntegrationTest
  def test_ログイン時にget_gadgetでカレンダーHTMLを取得できる
    sign_in user
    get get_gadget_calendars_path(display_date: Date.today.strftime('%Y-%m-%d'))
    assert_response :success
    assert_match %r{\A/calendars/get_gadget}, request.path
  end

  def test_未ログイン時はget_gadgetにアクセスできない
    get get_gadget_calendars_path(display_date: '2026-01-01')
    assert_response :redirect
  end

  def test_日本語ロケールで1月1日が祝日表示になる
    user.preference.update!(locale: 'ja')
    sign_in user
    get get_gadget_calendars_path(display_date: '2026-01-01')
    assert_response :success
    assert_select 'div.holiday', text: '1', count: 1
    assert_select 'div.content.holiday', text: '元日', count: 1
  end

  def test_英語ロケールでは祝日マークが付かない
    user.preference.update!(locale: 'en')
    sign_in user
    get get_gadget_calendars_path(display_date: '2026-01-01')
    assert_response :success
    assert_select 'div.holiday', count: 0
  end

  def test_use_calendarがオフのときget_gadgetは404
    user.preference.update!(use_calendar: false)
    sign_in user
    get get_gadget_calendars_path(display_date: '2026-01-01')
    assert_response :not_found
  end
end
