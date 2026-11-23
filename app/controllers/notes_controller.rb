class NotesController < ApplicationController
  before_action :set_note, only: [:update, :destroy]

  def index
    head :not_found and return unless current_user.preference.use_note?

    assign_note_gadget!
  end

  def create
    @note = Note.new(note_params)

    if @note.save
      if request.xhr?
        render partial: 'note_item', locals: { note: @note }, layout: false
      else
        redirect_to notes_path
      end
    else
      error_msg = @note.errors.full_messages.to_sentence.presence || t('flash.errors.generic')
      if request.xhr?
        render plain: error_msg, status: :unprocessable_entity
      else
        redirect_to notes_path, alert: error_msg
      end
    end
  end

  def update
    if @note.update(note_params)
      if request.xhr?
        render partial: 'note_item', locals: { note: @note }, layout: false
      else
        redirect_to notes_path
      end
    else
      error_msg = @note.errors.full_messages.to_sentence.presence || t('flash.errors.generic')
      if request.xhr?
        render plain: error_msg, status: :unprocessable_entity
      else
        redirect_to notes_path, alert: error_msg
      end
    end
  end

  def destroy
    @note.destroy_logically!
    if request.xhr?
      head :no_content
    else
      redirect_to notes_path
    end
  end

  private

  def assign_note_gadget!
    @note = Note.new
    @notes = current_user.notes.active.recent
  end

  def set_note
    @note = current_user.notes.active.find(params[:id])
  end

  def note_params
    params.require(:note).permit(:body).merge(user_id: current_user.id)
  end
end
