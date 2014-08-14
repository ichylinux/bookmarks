require 'test_helper'

class CalendarsControllerTest < ActionController::TestCase

  def test_カレンダーがまだなければ追加に遷移
    sign_in user_without_calendar
    assert Calendar.where('user_id = ?', user_without_calendar).empty?

    get :index
    assert_response :redirect
    assert_redirected_to :action => 'new'
  end

  def test_一覧はないので参照に遷移
    sign_in user
    assert calendar = Calendar.where('user_id = ?', user).first

    get :index
    assert_response :redirect
    assert_redirected_to :action => 'show', :id => calendar.id
  end

  def test_他人のカレンダーは参照できない
    sign_in user
    assert calendar = Calendar.where('user_id <> ?', user).first

    get :show, :id => calendar.id
    assert_response :not_found    
  end

  def test_追加
    sign_in user_without_calendar
    get :new
    assert_response :success
    assert_template :new
  end

  def test_登録
    sign_in user_without_calendar
    post :create, :calendar => valid_calendar_params(user_without_calendar)
    assert_response :redirect
    assert_redirected_to :action => 'show', :id => assigns(:calendar).id
  end

  def test_登録_入力エラー
    sign_in user_without_calendar
    post :create, :calendar => invalid_calendar_params(user_without_calendar)
    assert_response :success
    assert_template :new
  end

  def test_編集
    sign_in user
    get :edit, :id => calendar(user)
    assert_response :success
    assert_template :edit
  end
  
  def test_更新
    sign_in user
    put :update, :id => calendar(user), :calendar => valid_calendar_params(user)
    assert_response :redirect
    assert_redirected_to :action => 'show', :id => assigns(:calendar).id
  end

  def test_更新_入力エラー
    sign_in user
    put :update, :id => calendar(user), :calendar => invalid_calendar_params(user)
    assert_response :success
    assert_template :edit
  end

  def test_削除
    sign_in user
    assert_difference 'Calendar.not_deleted.count', -1 do
      delete :destroy, :id => calendar(user)
    end
    assert_response :redirect
    assert_redirected_to :action => 'index'
  end

  def test_ガジェットの取得
    sign_in user
    get :get_gadget, :id => calendar(user), :display_date => Date.today.strftime('%Y-%m-%d')
    assert_response :success
    assert_template :get_gadget
  end
end
