Rails.application.routes.draw do

  post "/login", to: 'sessions#create'
  delete '/logout', to: 'sessions#destroy'
  get "/me", to: 'users#show_me'
  resources :users

  resources :visits, defaults: { format: :json }
  resources :dresses

  root 'home#index'

  # Health check route for monitoring
  get "up" => "rails/health#show", as: :rails_health_check
end
