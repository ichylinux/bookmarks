class TodosController < ApplicationController
  before_filter :load_todo, :only => ['edit', 'update', 'destroy']
  
  def index
    @todos = Todo.where(:user_id => current_user).not_deleted.order(:title)
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
