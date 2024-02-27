class Meeting < ApplicationRecord
  belongs_to :commande, optional: true
  belongs_to :client, optional: true

  validates :datedebut, uniqueness: true

  LIEU_OPTIONS = ['boutique', 'exterieur']

  def full_name
    if client.present?
      "#{nom} - #{client.full_name}"
    elsif commande.present?
      "#{commande.client.full_name}" 
    else
      nom 
    end 
  end
  
  def full_details
    if client.present?
       "#{client.full_name} - #{client.tel}"
    elsif commande_id.present?
       "#{commande.client.full_name} - #{commande.client.tel}"     
    else
      nom     
    end 
  end


  def start_time
    datedebut
  end

  def end_time
    datefin
  end

end
