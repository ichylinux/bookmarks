# coding: UTF-8

class WelcomeController < ApplicationController

  def index
    @bookmarks = Bookmark.not_deleted
  end

end
