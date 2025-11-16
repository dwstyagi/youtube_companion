Rails.application.routes.draw do
  # OAuth routes for YouTube authentication
  get 'oauth/authorize', to: 'o_auth#authorize', as: :oauth_authorize
  get 'oauth/callback', to: 'o_auth#callback', as: :oauth_callback
  delete 'oauth/revoke', to: 'o_auth#revoke', as: :oauth_revoke

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"
end
