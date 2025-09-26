Rails.application.routes.draw do
  mount Rswag::Api::Engine => "/api-docs"
  mount Rswag::Ui::Engine => "/api-docs"

  namespace :api do
    namespace :v1 do
      resources :weathers, only: [:show]

      devise_for :users,
                 defaults: { format: :json },
                 path: "",
                 path_names: {
                   sign_in: "login",
                   sign_out: "logout",
                   registration: "signup",
                 },
                 controllers: {
                   sessions: "api/v1/sessions",
                   registrations: "api/v1/registrations",
                 }
    end
  end

  resources :weathers do
    collection do
      get :search
    end
  end

  resources :reports, only: [:index] do
    collection do
      post :export
    end
    member do
      get :download
    end
  end

  devise_for :users

  # Public pages
  get "home", to: "pages#home"

  # Root route - redirect based on authentication
  authenticated :user do
    root "weathers#index", as: :authenticated_root
  end

  unauthenticated do
    root "pages#home"
  end
end
