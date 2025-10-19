Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  # root "posts#index"

  # routes.rb
  post "auth/:provider/callback" => "sessions#callback"

  root "sessions#new"

  get "/home", to: "home#welcome"

  get "/auth/:provider/callback", to: "sessions#callback"
  get "/logout", to: "sessions#destroy"

  # HubSpot OAuth & sync
  get '/hubspot/connect', to: 'hubspot#hubspot_auth', as: :hubspot_connect
  get '/hubspot/callback', to: 'hubspot#hubspot_callback', as: :hubspot_callback_integrations

  post '/hubspot/sync', to: 'hubspot#sync_data', as: :hubspot_sync_data
  delete '/hubspot/disconnect', to: 'hubspot#disconnect_hubspot', as: :hubspot_disconnect
end
