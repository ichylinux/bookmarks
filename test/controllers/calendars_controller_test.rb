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

  def test_登録
    sign_in user_without_calendar
    post calendars_path, :params => {:calendar => valid_calendar_params(user_without_calendar)}
    assert_response :redirect
  end

  def test_登録_入力エラー
    sign_in user_without_calendar
    post calendars_path, :params => {:calendar => invalid_calendar_params(user_without_calendar)}
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
  
  def test_更新
    calendar = calendar(user)
    sign_in user

    patch calendar_path(calendar), :params => {:calendar => valid_calendar_params(user)}
    assert_response :redirect
    follow_redirect!
    assert_equal "/calendars/#{calendar.id}", path
  end

  def test_更新_入力エラー
    calendar = calendar(user)
    sign_in user

    patch calendar_path(calendar), :params => {:calendar => invalid_calendar_params(user)}
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

  def test_ガジェットの取得
    calendar = calendar(user)
    sign_in user

    get get_gadget_calendar_path(calendar), :params => {:display_date => Date.today.strftime('%Y-%m-%d')}
    assert_response :success
    assert_equal "/calendars/#{calendar.id}/get_gadget", path
  end
end
