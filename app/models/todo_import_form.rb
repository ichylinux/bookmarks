# coding: UTF-8

require 'csv'

class TodoImportForm < Daddy::Model
  include TodoConst

  def build
    CSV.readlines(self.file.open).each_with_index do |line, i|
      next unless line.length == 2
      self.todos << Todo.new(:title => line[1], :priority => PRIORITIES.invert[line[0]])
    end

    self
  end

  def todos
    unless @todos
      @todos = []
    
      self.todo.values.each do |t|
        @todos << Todo.new(:title => t[:title], :priority => t[:priority])
      end if self.todo.present?
    end
    
    @todos
  end

end