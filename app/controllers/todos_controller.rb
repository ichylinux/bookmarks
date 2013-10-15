# coding: UTF-8

class TodosController < ApplicationController
  
  def index
    @todos = Todo.where(:user_id => current_user).not_deleted.order(:title)
  end

  def destroy
    @todo = Todo.find(params[:id])
    
    @todo.transaction do
      @todo.destroy_logically!
    end
    
    redirect_to :action => 'index'
  end

  def new_import
    @todo_import_form = TodoImportForm.new
  end

  def confirm_import
    @todo_import_form = TodoImportForm.new(params[:todo_import_form]).build
  end

  def import
    @todo_import_form = TodoImportForm.new(params[:todo_import_form])
    
    Todo.transaction do
      @todo_import_form.todos.each do |t|
        t.user = current_user
        t.save!
      end
    end
    
    redirect_to :action => 'index'
  end

end
