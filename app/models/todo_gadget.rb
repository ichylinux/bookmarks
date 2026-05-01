class TodoGadget
  
  def initialize(todos)
    @todos = todos
  end

  def gadget_id
    'todo'
  end

  def title
    I18n.t('gadgets.todo.title')
  end
  
  def entries
    @todos
  end

end