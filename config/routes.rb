Rails.application.routes.draw do
  resources :weathers
  devise_for :users
  # suas outras rotas
  root "home#index"
end
