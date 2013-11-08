# coding: UTF-8

class Portal

  def initialize(user)
    @user = user
  end

  def user
    @user
  end

  def column_count
    columns.size
  end

  def columns
    gadgets
  end

  def gadgets
    return @gadgets if @gadgets

    @gadgets = [[], [], []]
    count = 0

    bookmarks = Bookmark.where(:user_id => user).not_deleted.order(:title)
    if bookmarks.present?
      @gadgets[count % 3] << BookmarkGadget.new(bookmarks)
      count += 1
    end

    todos = Todo.where(:user_id => user).not_deleted.order(:priority, :title)
    if todos.present?
      @gadgets[count % 3] << TodoGadget.new(todos)
      count += 1
    end
    
    Feed.where(:user_id => user).not_deleted.each do |f|
      @gadgets[count % 3] << f
      count += 1
    end

    gadgets
  end

  def update_layout(params = {})
    now = Time.now

    params.each do |column, gadget_ids|
      column_no = column.split('_').last.to_i
      
      gadget_ids.each_with_index do |gadget_id, i|
        pl = PortalLayout.where(:user_id => user.id, :column_no => column_no, :display_order => i).first
        pl ||= PortalLayout.new(:user_id => user.id, :column_no => column_no, :display_order => i)
        pl.gadget_id = gadget_id
        pl.save!
      end
    end

    PortalLayout.delete_all(['user_id = ? and updated_at < ?', user.id, now])
  end

end