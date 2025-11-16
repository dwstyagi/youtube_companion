class NotesController < ApplicationController
  before_action :set_video
  before_action :set_note, only: [:update, :destroy]

  def create
    @note = @video.notes.build(note_params)

    if @note.save
      # Log event
      EventLog.log_event('note_created', { note_id: @note.id, video_id: @video.id }, request)
      redirect_to video_path(@video), notice: 'Note added successfully!'
    else
      redirect_to video_path(@video), alert: 'Failed to add note'
    end
  end

  def update
    if @note.update(note_params)
      # Log event
      EventLog.log_event('note_updated', { note_id: @note.id, video_id: @video.id }, request)
      redirect_to video_path(@video), notice: 'Note updated successfully!'
    else
      redirect_to video_path(@video), alert: 'Failed to update note'
    end
  end

  def destroy
    @note.destroy
    # Log event
    EventLog.log_event('note_deleted', { note_id: @note.id, video_id: @video.id }, request)
    redirect_to video_path(@video), notice: 'Note deleted successfully!'
  end

  private

  def set_video
    @video = Video.find(params[:video_id])
  end

  def set_note
    @note = @video.notes.find(params[:id])
  end

  def note_params
    params.require(:note).permit(:content)
  end
end
