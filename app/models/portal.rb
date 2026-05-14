class Portal < ApplicationRecord
  belongs_to :user, inverse_of: 'portals'
  validates :name, presence: true

  def portal_column_count
    user.preference.portal_column_count
  end

  def portal_columns
    return @portal_columns if @portal_columns

    gadgets = get_gadgets
    count = portal_column_count
    @portal_columns = Array.new(count) { [] }

    PortalLayout.where(user_id: user.id).order('column_no, display_order').each do |pl|
      next if pl.column_no >= count
      g = gadgets.delete(pl.gadget_id)
      @portal_columns[pl.column_no] << g if g
    end

    gadgets.each_with_index do |g, i|
      @portal_columns[i % count].unshift(g[1])
    end

    @portal_columns
  end

  def update_layout(params = {})
    valid_layouts = []

    params.each do |column, gadget_ids|
      column_no = column.split('_').last.to_i
      
      gadget_ids.each_with_index do |gadget_id, i|
        pl = PortalLayout.where(user_id: user.id, column_no: column_no, display_order: i).first
        pl ||= PortalLayout.new(user_id: user.id, column_no: column_no, display_order: i)
        pl.gadget_id = gadget_id
        pl.save!
        
        valid_layouts << pl.id
      end
    end

    PortalLayout.where(user_id: user.id).where.not(id: valid_layouts).each(&:destroy)
  end

  private

  def get_gadgets
    ret = {}
    
    gadget = BookmarkGadget.new(user)
    if gadget.visible?
      ret[gadget.gadget_id] = gadget
    end

    if user.preference.use_todo?
      todos = Todo.where(user_id: user.id).not_deleted.order(:priority, :title)
      gadget = TodoGadget.new(todos) 
      ret[gadget.gadget_id] = gadget
    end

    if user.preference.use_calendar?
      cal = CalendarGadget.new(user)
      ret[cal.gadget_id] = cal
    end

    Feed.where(user_id: user.id).not_deleted.each do |f|
      ret[f.gadget_id] = f
    end

    MastodonAccount.where(user_id: user.id).not_deleted.each do |m|
      ret[m.gadget_id] = m
    end

    XAccount.where(user_id: user.id).not_deleted.where(selected: true).each do |x|
      ret[x.gadget_id] = x
    end

    ret
  end

end