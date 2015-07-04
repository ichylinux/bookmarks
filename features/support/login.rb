module Login

  def sign_in(user)
    visit '/users/sign_in'
    fill_in 'Email', :with => user.email
    fill_in 'Password', :with => 'testtest'
    click_on 'Log in'

    if user.need_two_factor_authentication?
      fill_in 'code', :with => User.find(user.id).otp_code
      click_on 'Submit'
    end

    @_current_user = user
  end

  def current_user
    @_current_user
  end
end

World(Login)
