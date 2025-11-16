class VideosController < ApplicationController
  include YoutubeAuthentication

  before_action :set_video, only: [:show, :update, :destroy]

  def index
    @videos = Video.recent
    @youtube_authorized = youtube_authorized?
  end

  def show
    @notes = @video.notes.recent
    @youtube_authorized = youtube_authorized?

    # Fetch latest stats from YouTube if authorized
    if youtube_authorized?
      begin
        video_data = youtube_service.fetch_video_details(@video.youtube_video_id)
        if video_data
          @video.update(
            view_count: video_data[:view_count],
            like_count: video_data[:like_count],
            comment_count: video_data[:comment_count]
          )
        end
      rescue => e
        Rails.logger.error "Failed to fetch video stats: #{e.message}"
      end
    end

    # Log event
    EventLog.log_event('video_viewed', { video_id: @video.id }, request)
  end

  def new
    @video = Video.new
  end

  def create
    youtube_video_id = extract_video_id(params[:video][:youtube_url])

    unless youtube_video_id
      redirect_to root_path, alert: 'Invalid YouTube URL'
      return
    end

    # Check if video already exists
    existing_video = Video.find_by(youtube_video_id: youtube_video_id)
    if existing_video
      redirect_to video_path(existing_video), notice: 'Video already exists in the system'
      return
    end

    # Fetch video details from YouTube
    service = youtube_authorized? ? youtube_service : YoutubeService.new
    video_data = service.fetch_video_details(youtube_video_id)

    unless video_data
      redirect_to root_path, alert: 'Failed to fetch video details from YouTube'
      return
    end

    @video = Video.new(video_data)

    if @video.save
      # Log event
      EventLog.log_event('video_fetched', { video_id: @video.id, youtube_video_id: youtube_video_id }, request)
      redirect_to video_path(@video), notice: 'Video successfully added!'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def sync
    unless youtube_authorized?
      redirect_to oauth_authorize_path, alert: 'Please connect your YouTube account first.'
      return
    end

    @video = Video.find(params[:id])
    video_data = youtube_service.fetch_video_details(@video.youtube_video_id)

    if video_data && @video.update(video_data)
      # Log event
      EventLog.log_event('video_synced', { video_id: @video.id }, request)
      redirect_to video_path(@video), notice: 'Video details synced successfully!'
    else
      redirect_to video_path(@video), alert: 'Failed to sync video details'
    end
  end

  def update
    unless youtube_authorized?
      redirect_to oauth_authorize_path, alert: 'Please connect your YouTube account to update videos.'
      return
    end

    title = params[:video][:title]
    description = params[:video][:description]

    # Update on YouTube
    result = youtube_service.update_video(
      @video.youtube_video_id,
      title: title,
      description: description
    )

    if result[:success]
      # Update local database
      @video.update(title: title, description: description)

      # Log event
      EventLog.log_event('video_updated', { video_id: @video.id, title: title }, request)

      redirect_to video_path(@video), notice: 'Video updated successfully on YouTube!'
    else
      redirect_to video_path(@video), alert: "Failed to update video: #{result[:error]}"
    end
  end

  def destroy
    @video.destroy
    redirect_to root_path, notice: 'Video removed from database'
  end

  private

  def set_video
    @video = Video.find(params[:id])
  end

  def extract_video_id(url)
    # Support various YouTube URL formats
    return nil if url.blank?

    patterns = [
      /(?:youtube\.com\/watch\?v=|youtu\.be\/)([^&\?\/]+)/,
      /youtube\.com\/embed\/([^&\?\/]+)/,
      /youtube\.com\/v\/([^&\?\/]+)/
    ]

    patterns.each do |pattern|
      match = url.match(pattern)
      return match[1] if match
    end

    # If no pattern matches, assume it's just the video ID
    url if url.match?(/^[a-zA-Z0-9_-]{11}$/)
  end
end
