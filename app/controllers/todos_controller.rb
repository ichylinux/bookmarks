class TodosController < ApplicationController
  before_action :preload_todo, only: ['edit', 'update', 'destroy']
  
  def index
    @todos = Todo.where(user_id: current_user).not_deleted.order(:title)
  end

  def new
    @todo = Todo.new(user: current_user, priority: current_user.preference.default_priority)
    render layout: !request.xhr?
  end

  def create
    @todo = Todo.new(todo_params)
    
    @todo.transaction do
      @todo.save!
    end

    render partial: 'todo', locals: { todo: @todo }
  end

  def edit
    render layout: !request.xhr?
  end

  def update
    @todo.attributes = todo_params

    @todo.transaction do
      @todo.save!
    end

    render partial: 'todo', locals: { todo: @todo }
  end

  def destroy
    @todo.transaction do
      @todo.destroy_logically!
    end
    
    redirect_to action: 'index'
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
    
    head :ok
  end

  private

  def preload_todo
    @todo = Todo.find(params[:id])

    unless @todo.readable_by?(current_user)
      head :not_found and return
    end
  end

  def todo_params
    ret = params.require(:todo).permit(:title, :priority)
    
    case action_name
    when 'create'
      ret = ret.merge(user_id: current_user.id)
    end
    
    ret
  end

end
