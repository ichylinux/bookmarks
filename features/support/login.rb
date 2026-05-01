module Login

  def sign_in(user)
    visit '/users/sign_in'

    fill_in 'user[email]', with: user.email
    fill_in 'user[password]', with: 'testtest'
    find('input[type="submit"], button[type="submit"]', match: :first).click

    if user.two_factor_enabled?
      totp = ROTP::TOTP.new(user.otp_secret)
      fill_in 'user[otp_attempt]', with: totp.now
      find('input[type="submit"], button[type="submit"]', match: :first).click
    end

    @_current_user = user
  end

  def current_user
    @_current_user
  end
end

World(Login)
