# coding: UTF-8

class WelcomeController < ApplicationController

  def index
    @bookmarks = Bookmark.where(:user_id => current_user).not_deleted.order(:title)
  end

end
