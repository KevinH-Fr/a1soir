Rails.application.routes.draw do
  get 'users/index'

  get 'stock/index'
  
  resources :doc_editions do 
    member do
      post :edit
    end
  end

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

  resources :profiles do 
    member do
      post :edit
    end
  end

  resources :meetings do 
    member do
      post :edit
    end
  end


  resources :messagemails
  resources :sousarticles
  resources :textes
  resources :messages
  
  devise_for :users
  
  resources :users do
    member do
      #get :toggle_status
      get :toggle_status_user
      get :toggle_status_vendeur
      get :toggle_status_admin
      get :editer_mail
    end
  end

  #pdf generation 

  get '/generate_commande_doc_editions', to: 'doc_editions#generate_commande'
  post '/send_email', to: 'doc_editions#send_email'


  get "home_admin", to: "home_admin#index"

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  root "home_admin#index"
end
