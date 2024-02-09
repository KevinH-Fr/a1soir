Rails.application.routes.draw do
  
  resources :avoir_rembs
  resources :paiement_recus
  resources :paiements
  resources :messagemails
  resources :meetings
  resources :sousarticles
  resources :articles
  resources :commandes
  resources :produits
  resources :fournisseurs
  resources :categorie_produits
  resources :clients
  resources :profiles
  resources :textes
  resources :messages
  
  devise_for :users
  
  
  get "home_admin", to: "home_admin#index"

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  root "home_admin#index"
end
