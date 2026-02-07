module Login

  def sign_in(user)
    visit '/users/sign_in'

    fill_in 'Eメール', :with => user.email
    fill_in 'パスワード', :with => 'testtest'
    click_on 'ログイン'

    @_current_user = user
  end

  def current_user
    @_current_user
  end
end

World(Login)
