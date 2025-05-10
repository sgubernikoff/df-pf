Rails.application.routes.draw do
  resources :visits, defaults: { format: :json }
  resources :dresses

  root 'home#index'

  # Health check route for monitoring
  get "up" => "rails/health#show", as: :rails_health_check
end
