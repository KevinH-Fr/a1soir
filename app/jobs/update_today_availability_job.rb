class UpdateTodayAvailabilityJob < ApplicationJob
  queue_as :default

  # Job quotidien pour recalculer la disponibilité de tous les produits
  # Ce job sert de filet de sécurité pour s'assurer que toutes les disponibilités sont à jour
  # Il est complété par des callbacks en temps réel sur les modèles concernés
  def perform
    datedebut = Time.current
    datefin = Time.current
    
    puts "_____Début du calcul de disponibilité pour #{Produit.count} produits_____________"
    
    # Calculer la disponibilité pour tous les produits
    Produit.find_each do |produit|
      # Utiliser la méthode update_today_availability qui calcule et met à jour le champ
      produit.update_today_availability(datedebut, datefin)
    end
    
    puts "_____Fin du calcul de disponibilité_____________"
  end
end

