Rails.application.routes.draw do
  resources :labels

  devise_for :users
  resources :produits
  resources :clients
  resources :posts
  resources :annonces
  
  # partie publique
   root 'accueil#index' 
   get 'contact', to: 'accueil#contact'
   get 'boutique', to: 'accueil#boutique'
   get 'robes_soirees', to: 'accueil#soirees'
   get 'robes_mariees', to: 'accueil#mariees'
   get 'costumes_hommes', to: 'accueil#costumes'
   get 'accessoires', to: 'accueil#accessoires'
   get 'costumes_deguisements', to: 'accueil#deguisements'
   get 'plan', to: 'accueil#plan'
   
   # partie admin
   get 'accueil_admin', to: 'accueil_admin#index'
   get 'search', to: 'search#index'
   get 'marketing', to: 'accueil_admin#marketing'

end
