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

  # ✅ Custom working health check route
  get '/up', to: proc { [200, { 'Content-Type' => 'application/json' }, ['{"status":"ok"}']] }

  root 'home#index'
end
