Rails.application.routes.draw do
  
  resources :produits
  resources :clients
  resources :posts
  
   root 'accueil#index' 
   get 'accueil_admin', to: 'accueil_admin#index'

end
