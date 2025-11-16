class CommentsController < ApplicationController
  include YoutubeAuthentication

  before_action :require_youtube_authorization
  before_action :set_video

  def index
    begin
      @comments = youtube_service.fetch_comments(@video.youtube_video_id)
    rescue => e
      Rails.logger.error "Fetch Comments Error: #{e.message}"
      @comments = []
      flash.now[:alert] = "Failed to load comments: #{e.message}"
    end
  end

  def create
    begin
      comment_text = params[:comment][:text]
      result = youtube_service.post_comment(@video.youtube_video_id, comment_text)

      if result[:success]
        # Log event
        EventLog.log_event('comment_created', {
          video_id: @video.id,
          youtube_comment_id: result[:comment_id]
        }, request)

        redirect_to video_comments_path(@video), notice: 'Comment posted successfully!'
      else
        redirect_to video_comments_path(@video), alert: "Failed to post comment: #{result[:error]}"
      end
    rescue => e
      Rails.logger.error "Post Comment Error: #{e.message}"
      redirect_to video_comments_path(@video), alert: "Failed to post comment: #{e.message}"
    end
  end

  def reply
    begin
      parent_comment_id = params[:parent_comment_id]
      reply_text = params[:comment][:text]

      result = youtube_service.reply_to_comment(parent_comment_id, reply_text)

      if result[:success]
        # Log event
        EventLog.log_event('comment_reply_created', {
          video_id: @video.id,
          parent_comment_id: parent_comment_id,
          youtube_comment_id: result[:comment_id]
        }, request)

        redirect_to video_comments_path(@video), notice: 'Reply posted successfully!'
      else
        redirect_to video_comments_path(@video), alert: "Failed to post reply: #{result[:error]}"
      end
    rescue => e
      Rails.logger.error "Post Reply Error: #{e.message}"
      redirect_to video_comments_path(@video), alert: "Failed to post reply: #{e.message}"
    end
  end

  def destroy
    begin
      comment_id = params[:comment_id]
      result = youtube_service.delete_comment(comment_id)

      if result[:success]
        # Log event
        EventLog.log_event('comment_deleted', {
          video_id: @video.id,
          youtube_comment_id: comment_id
        }, request)

        redirect_to video_comments_path(@video), notice: 'Comment deleted successfully!'
      else
        redirect_to video_comments_path(@video), alert: "Failed to delete comment: #{result[:error]}"
      end
    rescue => e
      Rails.logger.error "Delete Comment Error: #{e.message}"
      redirect_to video_comments_path(@video), alert: "Failed to delete comment: #{e.message}"
    end
  end

  private

  def set_video
    @video = Video.find(params[:video_id])
  end
end
