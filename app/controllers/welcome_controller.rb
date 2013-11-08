# coding: UTF-8

class WelcomeController < ApplicationController

  def index
    @gadgets = [[], [], []]
    count = 0

    @bookmarks = Bookmark.where(:user_id => current_user).not_deleted.order(:title)
    if @bookmarks.present?
      @gadgets[count % 3] << BookmarkGadget.new(@bookmarks)
      count += 1
    end

    @todos = Todo.where(:user_id => current_user).not_deleted.order(:priority, :title)
    if @todos.present?
      @gadgets[count % 3] << TodoGadget.new(@todos)
      count += 1
    end
    
    Feed.where(:user_id => current_user).not_deleted.each do |f|
      @gadgets[count % 3] << f
      count += 1
    end
  end

end
