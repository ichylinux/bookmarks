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
    return @columns if @columns

    gadgets = get_gadgets
    @columns = [[], [], []]

    PortalLayout.where(:user_id => user.id).order('column_no, display_order').each do |pl|
      g = gadgets.delete(pl.gadget_id)
      @columns[pl.column_no] << g if g
    end

    gadgets.each_with_index do |g, i|
      @columns[i % 3].unshift(g[1])
    end
    
    columns
  end

  def get_gadgets
    ret = {}
    
    bookmarks = Bookmark.where(:user_id => user).not_deleted.order(:title)
    if bookmarks.present?
      gadget = BookmarkGadget.new(bookmarks) 
      ret[gadget.gadget_id] = gadget
    end

    todos = Todo.where(:user_id => user).not_deleted.order(:priority, :title)
    if todos.present?
      gadget = TodoGadget.new(todos) 
      ret[gadget.gadget_id] = gadget
    end
    
    Feed.where(:user_id => user).not_deleted.each do |f|
      ret[f.gadget_id] = f
    end

    ret
  end

  def update_layout(params = {})
    now = Time.now

    params.each do |column, gadget_ids|
      column_no = column.split('_').last.to_i
      
      gadget_ids.each_with_index do |gadget_id, i|
        pl = PortalLayout.where(:user_id => user.id, :column_no => column_no, :display_order => i).first
        pl ||= PortalLayout.new(:user_id => user.id, :column_no => column_no, :display_order => i)
        pl.gadget_id = gadget_id
        pl.updated_at = now
        pl.save!
      end
    end

    PortalLayout.where('user_id = ? and updated_at < ?', user.id, now).each do |pl|
      pl.destroy
    end
  end

end