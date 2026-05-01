class NotesController < ApplicationController
  def create
    @note = Note.new(note_params)

    if @note.save
      redirect_to root_path(tab: 'notes')
    else
      redirect_to root_path(tab: 'notes'),
                  alert: @note.errors.full_messages.to_sentence.presence || t('flash.errors.generic')
    end
  end

  private

  def note_params
    params.require(:note).permit(:body).merge(user_id: current_user.id)
  end
end
