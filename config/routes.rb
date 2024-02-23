Rails.application.routes.draw do
  
  resources :doc_editions
  get 'stock/index'
  

  resources :categorie_produits do 
    member do
      post :edit
    end
  end

  resources :fournisseurs do 
    member do
      post :edit
    end
  end

  resources :produits do 
    member do
      post :edit
    end
  end


  resources :couleurs do 
    member do
      post :edit
    end
  end

  resources :tailles do 
    member do
      post :edit
    end
  end

  resources :clients do 
    member do
      post :edit
    end
  end

  resources :commandes do 
    member do
      post :edit
    end

    collection do
      post 'selection_articles'
    end
  end

  resources :articles do 
    member do
      post :edit
    end
  end

  
  resources :paiement_recus do 
    member do
      post :edit
    end
  end

  resources :avoir_rembs do 
    member do
      post :edit
    end
  end

  resources :messagemails
  resources :meetings
  resources :sousarticles
  resources :profiles
  resources :textes
  resources :messages
  
  devise_for :users
  
  #pdf generation 


  get '/generate_commande_pdf', to: 'pdf#generate_commande'

  get '/choix_edition', to: 'commandes#choix_edition_bis'

  post '/send_email', to: 'pdf#send_email'

  get "home_admin", to: "home_admin#index"

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  root "home_admin#index"
end
