class LoginMailer < ActionMailer::Base
  default :from => 'info@bookmarks.reading.jp'
  
  def mail(headers = {})
    m = super
    m.transport_encoding = '8bit'
    m
  end

  def invoice_login(user, params = {})
    @user = user

    mail(
      :subject => "Bookmarksにログインしました",
      :to => @user.email
    )
  end
  
end
