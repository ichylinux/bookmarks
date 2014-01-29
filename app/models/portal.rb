# coding: UTF-8

class Portal < ActiveRecord::Base

  belongs_to :user

  validates :name, :presence => true

  def portal_column_count
    portal_columns.size
  end

  def portal_columns
    return @portal_columns if @portal_columns

    gadgets = get_gadgets
    @portal_columns = [[], [], []]

    PortalLayout.where(:user_id => user.id).order('column_no, display_order').each do |pl|
      g = gadgets.delete(pl.gadget_id)
      @portal_columns[pl.column_no] << g if g
    end

    gadgets.each_with_index do |g, i|
      @portal_columns[i % 3].unshift(g[1])
    end
    
    portal_columns
  end

  def update_layout(params = {})
    valid_layouts = []

    params.each do |column, gadget_ids|
      column_no = column.split('_').last.to_i
      
      gadget_ids.each_with_index do |gadget_id, i|
        pl = PortalLayout.where(:user_id => user.id, :column_no => column_no, :display_order => i).first
        pl ||= PortalLayout.new(:user_id => user.id, :column_no => column_no, :display_order => i)
        pl.gadget_id = gadget_id
        pl.save!
        
        valid_layouts << pl.id
      end
    end

    PortalLayout.where('user_id = ? and id not in(?)', user.id, valid_layouts).each do |pl|
      pl.destroy
    end
  end

  private

  def get_gadgets
    ret = {}
    
    bookmarks = Bookmark.where(:user_id => user.id).not_deleted.order(:title)
    if bookmarks.present?
      gadget = BookmarkGadget.new(bookmarks) 
      ret[gadget.gadget_id] = gadget
    end

    todos = Todo.where(:user_id => user.id).not_deleted.order(:priority, :title)
    if todos.present?
      gadget = TodoGadget.new(todos) 
      ret[gadget.gadget_id] = gadget
    end

    calendars = Calendar.where(:user_id => user.id).not_deleted.each do |c|
      ret[c.gadget_id] = c
    end

    Feed.where(:user_id => user.id).not_deleted.each do |f|
      ret[f.gadget_id] = f
    end

    ret
  end

end