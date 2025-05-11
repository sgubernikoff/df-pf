Rails.application.routes.draw do
  devise_for :users, path: '', path_names: {
    sign_in: 'login',
    sign_out: 'logout',
    registration: 'signup'
  },
  controllers: {
    sessions: 'users/sessions',
    registrations: 'users/registrations'
  }

  resources :protected_resources, only: [:index]

  get 'current_user', to: 'users#show_me'

  get "users/search", to: "users#search"

  resources :users

  resources :visits, defaults: { format: :json }
  resources :dresses

  root 'home#index'

  # Health check route for monitoring
  get "up" => "rails/health#show", as: :rails_health_check
end
