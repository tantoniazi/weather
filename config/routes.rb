Rails.application.routes.draw do
  mount Rswag::Api::Engine => "/api-docs"
  mount Rswag::Ui::Engine => "/api-docs"

  resources :weathers do
    collection do
      get :search
    end
  end

  resources :reports, only: [:index] do
    collection do
      post :export
    end
  end

  # API routes
  namespace :api do
    namespace :v1 do
      resources :weathers, only: [:show]
    end
  end

  devise_for :users
  root "weathers#index"
end
