class OAuthController < ApplicationController
  def authorize
    begin
      redirect_uri = oauth_callback_url(host: request.base_url)
      auth_url = YoutubeService.authorization_url(redirect_uri)
      redirect_to auth_url, allow_other_host: true
    rescue => e
      Rails.logger.error "OAuth Authorization Error: #{e.message}"
      redirect_to root_path, alert: "Failed to connect to YouTube. Please check your API credentials in .env file."
    end
  end

  def callback
    begin
      if params[:code]
        redirect_uri = oauth_callback_url(host: request.base_url)
        credentials = YoutubeService.get_access_token(params[:code], redirect_uri)

        if credentials
          session[:youtube_authorized] = true
          redirect_to root_path, notice: 'Successfully connected to YouTube!'
        else
          redirect_to root_path, alert: 'Failed to connect to YouTube.'
        end
      else
        redirect_to root_path, alert: 'Authorization cancelled.'
      end
    rescue => e
      Rails.logger.error "OAuth Callback Error: #{e.message}"
      redirect_to root_path, alert: "Failed to complete YouTube authorization: #{e.message}"
    end
  end

  def revoke
    # Remove stored credentials
    token_file = Rails.root.join('tmp', 'tokens.yaml')
    File.delete(token_file) if File.exist?(token_file)

    session[:youtube_authorized] = false
    redirect_to root_path, notice: 'YouTube connection revoked.'
  end
end
