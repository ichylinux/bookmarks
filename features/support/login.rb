module Login

  def sign_in(user)
    visit '/users/sign_in'

    fill_in 'Eメール', :with => user.email
    fill_in 'パスワード', :with => 'testtest'
    click_on 'ログイン'

    if user.two_factor_enabled?
      totp = ROTP::TOTP.new(user.otp_secret)
      fill_in '認証コード', :with => totp.now
      click_on '認証する'
    end

    @_current_user = user
  end

  def current_user
    @_current_user
  end
end

World(Login)
