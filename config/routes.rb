Rails.application.routes.draw do

  devise_for :users
  resources :produits
  resources :clients
  resources :posts
  
   root 'accueil#index' 
   get 'accueil_admin', to: 'accueil_admin#index'
   get 'contact', to: 'accueil#contact'
   get 'boutique', to: 'accueil#boutique'
   get 'robes_soirees', to: 'accueil#soirees'
   get 'robes_mariees', to: 'accueil#mariees'
   get 'costumes_hommes', to: 'accueil#costumes'
   get 'accessoires', to: 'accueil#accessoires'
   get 'costumes_deguisements', to: 'accueil#deguisements'
   get 'plan', to: 'accueil#plan'
   
   get 'search', to: 'search#index'

end
