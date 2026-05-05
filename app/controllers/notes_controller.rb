class NotesController < ApplicationController
  before_action :set_note, only: [:update, :destroy]

  def create
    @note = Note.new(note_params)

    if @note.save
      redirect_to root_path(tab: 'notes')
    else
      redirect_to root_path(tab: 'notes'),
                  alert: @note.errors.full_messages.to_sentence.presence || t('flash.errors.generic')
    end
  end

  def update
    if @note.update(note_params)
      redirect_to root_path(tab: 'notes')
    else
      redirect_to root_path(tab: 'notes'),
                  alert: @note.errors.full_messages.to_sentence.presence || t('flash.errors.generic')
    end
  end

  def destroy
    @note.destroy_logically!
    redirect_to root_path(tab: 'notes')
  end

  private

  def set_note
    @note = current_user.notes.active.find(params[:id])
  end

  def note_params
    params.require(:note).permit(:body).merge(user_id: current_user.id)
  end
end
