require 'google/apis/youtube_v3'
require 'googleauth'
require 'googleauth/stores/file_token_store'

class YoutubeService
  SCOPE = Google::Apis::YoutubeV3::AUTH_YOUTUBE_FORCE_SSL

  def initialize(access_token = nil)
    @service = Google::Apis::YoutubeV3::YouTubeService.new
    @service.client_options.application_name = 'YouTube Companion'

    if access_token
      @service.authorization = access_token
    else
      @service.key = ENV['YOUTUBE_API_KEY']
    end
  end

  # Fetch video details by video ID
  def fetch_video_details(video_id)
    response = @service.list_videos(
      'snippet,statistics,contentDetails',
      id: video_id
    )

    return nil if response.items.empty?

    video = response.items.first
    {
      youtube_video_id: video.id,
      title: video.snippet.title,
      description: video.snippet.description,
      thumbnail_url: video.snippet.thumbnails.high&.url || video.snippet.thumbnails.default.url,
      published_at: video.snippet.published_at,
      view_count: video.statistics.view_count.to_i,
      like_count: video.statistics.like_count.to_i,
      comment_count: video.statistics.comment_count.to_i
    }
  rescue Google::Apis::Error => e
    Rails.logger.error "YouTube API Error: #{e.message}"
    nil
  end

  # Update video details (title and description)
  def update_video(video_id, title: nil, description: nil)
    # First, get the current video details
    current_video = @service.list_videos('snippet', id: video_id).items.first
    return { success: false, error: 'Video not found' } unless current_video

    # Update the snippet
    snippet = current_video.snippet
    snippet.title = title if title.present?
    snippet.description = description if description.present?
    snippet.category_id = current_video.snippet.category_id

    # Create update request
    video_object = Google::Apis::YoutubeV3::Video.new(
      id: video_id,
      snippet: snippet
    )

    @service.update_video('snippet', video_object)
    { success: true }
  rescue Google::Apis::Error => e
    Rails.logger.error "YouTube API Error: #{e.message}"
    { success: false, error: e.message }
  end

  # Fetch comments for a video
  def fetch_comments(video_id, max_results: 20)
    response = @service.list_comment_threads(
      'snippet',
      video_id: video_id,
      max_results: max_results,
      order: 'time'
    )

    response.items.map do |item|
      comment = item.snippet.top_level_comment.snippet
      {
        id: item.snippet.top_level_comment.id,
        author: comment.author_display_name,
        text: comment.text_display,
        published_at: comment.published_at,
        like_count: comment.like_count,
        reply_count: item.snippet.total_reply_count
      }
    end
  rescue Google::Apis::Error => e
    Rails.logger.error "YouTube API Error: #{e.message}"
    []
  end

  # Post a comment on a video
  def post_comment(video_id, comment_text)
    comment_snippet = Google::Apis::YoutubeV3::CommentSnippet.new(
      text_original: comment_text
    )

    comment = Google::Apis::YoutubeV3::Comment.new(
      snippet: comment_snippet
    )

    comment_thread_snippet = Google::Apis::YoutubeV3::CommentThreadSnippet.new(
      video_id: video_id,
      top_level_comment: comment
    )

    comment_thread = Google::Apis::YoutubeV3::CommentThread.new(
      snippet: comment_thread_snippet
    )

    result = @service.insert_comment_thread('snippet', comment_thread)
    { success: true, comment_id: result.id }
  rescue Google::Apis::Error => e
    Rails.logger.error "YouTube API Error: #{e.message}"
    { success: false, error: e.message }
  end

  # Reply to a comment
  def reply_to_comment(parent_comment_id, reply_text)
    comment_snippet = Google::Apis::YoutubeV3::CommentSnippet.new(
      parent_id: parent_comment_id,
      text_original: reply_text
    )

    comment = Google::Apis::YoutubeV3::Comment.new(
      snippet: comment_snippet
    )

    result = @service.insert_comment('snippet', comment)
    { success: true, comment_id: result.id }
  rescue Google::Apis::Error => e
    Rails.logger.error "YouTube API Error: #{e.message}"
    { success: false, error: e.message }
  end

  # Delete a comment
  def delete_comment(comment_id)
    @service.delete_comment(comment_id)
    { success: true }
  rescue Google::Apis::Error => e
    Rails.logger.error "YouTube API Error: #{e.message}"
    { success: false, error: e.message }
  end

  # OAuth methods
  def self.authorization_url(redirect_uri)
    require 'signet/oauth_2/client'

    client = Signet::OAuth2::Client.new(
      client_id: ENV['YOUTUBE_CLIENT_ID'],
      client_secret: ENV['YOUTUBE_CLIENT_SECRET'],
      authorization_uri: 'https://accounts.google.com/o/oauth2/auth',
      redirect_uri: redirect_uri,
      scope: SCOPE
    )

    client.authorization_uri.to_s
  end

  def self.get_access_token(code, redirect_uri)
    require 'signet/oauth_2/client'

    client = Signet::OAuth2::Client.new(
      client_id: ENV['YOUTUBE_CLIENT_ID'],
      client_secret: ENV['YOUTUBE_CLIENT_SECRET'],
      token_credential_uri: 'https://oauth2.googleapis.com/token',
      redirect_uri: redirect_uri,
      code: code
    )

    client.fetch_access_token!

    # Store credentials
    store_credentials(client)

    client
  end

  def self.get_stored_credentials
    token_file = Rails.root.join('tmp', 'tokens.yaml')
    return nil unless File.exist?(token_file)

    require 'yaml'
    require 'signet/oauth_2/client'

    stored_data = YAML.safe_load(File.read(token_file), permitted_classes: [Symbol, Time])
    return nil unless stored_data

    # Convert timestamp back to Time if needed
    expires_at = stored_data['expires_at']
    expires_at = Time.at(expires_at) if expires_at.is_a?(Integer)

    client = Signet::OAuth2::Client.new(
      client_id: ENV['YOUTUBE_CLIENT_ID'],
      client_secret: ENV['YOUTUBE_CLIENT_SECRET'],
      token_credential_uri: 'https://oauth2.googleapis.com/token',
      access_token: stored_data['access_token'],
      refresh_token: stored_data['refresh_token'],
      expires_at: expires_at
    )

    # Refresh token if expired
    if client.expired?
      client.refresh!
      store_credentials(client)
    end

    client
  rescue => e
    Rails.logger.error "Failed to load credentials: #{e.message}"
    nil
  end

  def self.store_credentials(client)
    token_file = Rails.root.join('tmp', 'tokens.yaml')

    # Convert Time to integer timestamp for safe YAML storage
    expires_at = client.expires_at
    expires_at = expires_at.to_i if expires_at.is_a?(Time)

    data = {
      'access_token' => client.access_token,
      'refresh_token' => client.refresh_token,
      'expires_at' => expires_at
    }

    require 'yaml'
    File.write(token_file, data.to_yaml)
  end
end
