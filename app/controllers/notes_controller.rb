class NotesController < ApplicationController
  before_action :set_note, only: [:update, :destroy]

  def gadget
    @note  = Note.new
    @notes = current_user.notes.active.recent
    render layout: false
  end

  def create
    @note = Note.new(note_params)

    if @note.save
      if request.xhr?
        render partial: 'note_item', locals: { note: @note }, layout: false
      else
        redirect_to root_path(tab: 'notes')
      end
    else
      error_msg = @note.errors.full_messages.to_sentence.presence || t('flash.errors.generic')
      if request.xhr?
        render plain: error_msg, status: :unprocessable_entity
      else
        redirect_to root_path(tab: 'notes'), alert: error_msg
      end
    end
  end

  def update
    if @note.update(note_params)
      if request.xhr?
        render partial: 'note_item', locals: { note: @note }, layout: false
      else
        redirect_to root_path(tab: 'notes')
      end
    else
      error_msg = @note.errors.full_messages.to_sentence.presence || t('flash.errors.generic')
      if request.xhr?
        render plain: error_msg, status: :unprocessable_entity
      else
        redirect_to root_path(tab: 'notes'), alert: error_msg
      end
    end
  end

  def destroy
    @note.destroy_logically!
    if request.xhr?
      head :no_content
    else
      redirect_to root_path(tab: 'notes')
    end
  end

  private

  def set_note
    @note = current_user.notes.active.find(params[:id])
  end

  def note_params
    params.require(:note).permit(:body).merge(user_id: current_user.id)
  end
end
