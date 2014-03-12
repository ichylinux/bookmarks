require 'test_helper'

class CalendarsControllerTest < ActionController::TestCase

  def test_他人のカレンダーは参照できない
    sign_in user
    assert calendar = Calendar.where('user_id <> ?', user).first

    get :show, :id => calendar.id

    assert_response :not_found    
  end

end
