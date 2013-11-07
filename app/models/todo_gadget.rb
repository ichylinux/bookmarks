# coding: UTF-8

class TodoGadget
  
  def initialize(todos)
    @todos = todos
  end
  
  def title
    'Todo'
  end
  
  def entries
    @todos
  end

end