Rails.application.routes.draw do
  get 'analyses/index'

  resources :admin_parameters do 
    member do
      post :edit
    end
  end

  resources :friends do 
    member do
      post :edit
    end
  end

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

  resources :type_produits do 
    member do
      post :edit
    end
  end

  resources :ensembles do 
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
      get :dupliquer
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
      get :toggle_statut_retire
      get :toggle_statut_non_retire
      get :toggle_statut_rendu
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

  resources :sousarticles do 
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
    collection do
      get :download_ics # Define the download_ics route
    end
    member do
      post :edit
    end
  end

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


  get 'pdf_generator/generate_pdf'
  get 'users/index'

  get 'stock/index'

  #pdf generation 

  get '/generate_commande_doc_editions', to: 'doc_editions#generate_commande'
  post '/send_email', to: 'doc_editions#send_email'

  post '/send_reminder', to: 'meetings#send_reminder'
  post '/send_reminder_job', to: 'meetings#send_reminder_job'

  # etiquettes
  get 'etiquettes/index'

  resources :etiquettes do
    collection do
      post :reset_selection
      post :update_selection
      get :generate_pdf, defaults: { format: :pdf }  # Force the format to PDF
    end
  end
  
  get 'selection_produit', to: 'selection_produit#index'

  resources :selection_produit do
    collection do
      post 'display_qr'
      post 'display_manuelle'
      post 'display_categorie_selected'
      post 'display_taille_selected'
      post 'display_couleur_selected'
      post 'toggle_transformer_ensemble'
    end 
  end


  get "home_admin", to: "home_admin#index"
  get "home_admin_scan_qr", to: "home_admin#selection_qr"

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  root "home_admin#index"
end
