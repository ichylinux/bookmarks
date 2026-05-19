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
      redirect_to root_path(tab: 'notes')
    else
      redirect_to root_path(tab: 'notes'),
                  alert: @note.errors.full_messages.to_sentence.presence || t('flash.errors.generic')
    end
  end

  def update
    @updated = @note.update(note_params)
    @error   = @note.errors.full_messages.to_sentence.presence || t('flash.errors.generic') unless @updated
    respond_to do |format|
      format.html do
        @updated ? redirect_to(root_path(tab: 'notes')) : redirect_to(root_path(tab: 'notes'), alert: @error)
      end
      format.js
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
