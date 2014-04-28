class TodosController < ApplicationController
  before_filter :load_todo, :only => ['edit', 'update', 'destroy']
  
  def index
    @todos = Todo.where(:user_id => current_user).not_deleted.order(:title)
  end

  def new
    @todo = Todo.new(:user => current_user)
    render :layout => ! request.xhr?
  end

  def create
    @todo = Todo.new(params[:todo])
    @todo.user = current_user
    
    @todo.transaction do
      @todo.save!
    end

    render :partial => 'todo', :locals => {:todo => @todo}
  end

  def edit
    render :layout => ! request.xhr?
  end

  def update
    @todo.transaction do
      @todo.attributes = params[:todo]
      @todo.save!
    end

    render :partial => 'todo', :locals => {:todo => @todo}
  end

  def destroy
    @todo.transaction do
      @todo.destroy_logically!
    end
    
    redirect_to :action => 'index'
  end

  def delete
    if params[:todo_id].present?
      Todo.transaction do
        params[:todo_id].each do |id|
          @todo = Todo.find(id)
          @todo.destroy_logically!
        end
      end
    end
    
    render :nothing => true
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

  private

  def load_todo
    @todo = Todo.find(params[:id])

    unless @todo.readable_by?(current_user)
      render :nothing => true, :status => :not_found
      return
    end
  end

end
