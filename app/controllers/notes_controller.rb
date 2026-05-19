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
    if @note.update(note_params)
      respond_to do |format|
        format.html { redirect_to root_path(tab: 'notes') }
        format.json do
          updated_time = @note.updated_at.strftime('%Y-%m-%d %H:%M')
          render json: {
            id: @note.id,
            body: @note.body,
            created_time: @note.created_at.strftime('%Y-%m-%d %H:%M'),
            updated_time: updated_time,
            edited: @note.updated_at.to_i != @note.created_at.to_i,
            edited_tooltip: t('notes.gadget.edited_tooltip', time: updated_time),
            edited_badge: t('notes.gadget.edited_badge')
          }
        end
      end
    else
      error_msg = @note.errors.full_messages.to_sentence.presence || t('flash.errors.generic')
      respond_to do |format|
        format.html { redirect_to root_path(tab: 'notes'), alert: error_msg }
        format.json { render json: { error: error_msg }, status: :unprocessable_entity }
      end
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
