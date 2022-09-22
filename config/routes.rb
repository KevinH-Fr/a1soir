Rails.application.routes.draw do
  devise_for :users
  resources :produits
  resources :clients
  resources :posts
  
   root 'accueil#index' 
   get 'accueil_admin', to: 'accueil_admin#index'
   get 'contact', to: 'accueil#contact'
   get 'boutique', to: 'accueil#boutique'

end
