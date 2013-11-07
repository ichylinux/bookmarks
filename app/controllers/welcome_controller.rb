# coding: UTF-8

class WelcomeController < ApplicationController

  def index
    @bookmarks = Bookmark.where(:user_id => current_user).not_deleted.order(:title)
    @todos = Todo.where(:user_id => current_user).not_deleted.order(:priority, :title)
    @feeds = Feed.where(:user_id => current_user).not_deleted
  end

end
