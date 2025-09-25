Rails.application.routes.draw do
  mount Rswag::Api::Engine => '/api-docs'
  mount Rswag::Ui::Engine => '/api-docs'
  resources :weathers
  devise_for :users
  # suas outras rotas
  root "home#index"
end
