module YoutubeAuthentication
  extend ActiveSupport::Concern

  included do
    helper_method :youtube_authorized?, :youtube_service
  end

  def youtube_authorized?
    session[:youtube_authorized] == true && YoutubeService.get_stored_credentials.present?
  end

  def youtube_service
    credentials = YoutubeService.get_stored_credentials
    @youtube_service ||= YoutubeService.new(credentials)
  end

  def require_youtube_authorization
    unless youtube_authorized?
      redirect_to oauth_authorize_path, alert: 'Please connect your YouTube account first.'
    end
  end
end
