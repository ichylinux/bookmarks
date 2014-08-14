module Login

  def sign_in(user)
    visit '/users/sign_in'
    fill_in 'Email', :with => user.email
    fill_in 'Password', :with => 'testtest'
    click_on 'Log in'

    @_current_user = user
  end

  def current_user
    @_current_user
  end
end

World(Login)
