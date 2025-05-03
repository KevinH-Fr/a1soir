class Meeting < ApplicationRecord
  belongs_to :commande, optional: true
  belongs_to :client, optional: true

  validates :datedebut, presence: true #, uniqueness: true
  
  after_create :add_calendar_event
  after_update :update_calendar_event
  after_destroy :delete_calendar_event

  LIEU_OPTIONS = ['boutique', 'exterieur']

  def full_name
    if client.present?
      "#{client.full_name} - #{nom}"
    elsif commande.present?
      "#{commande.client.full_name} - #{nom}" 
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

  def adresse_rdv
    lieu == "boutique" ? "Autour d'un Soir 27-29 Boulevard Carnot 06400 Cannes" : lieu
  end

  def start_time
    datedebut
  end

  def end_time
    datefin
  end

  def full_date
    "#{datedebut.strftime('%d-%m %H:%M')} - #{datefin.strftime('%H:%M')}"
  end

  def meeting_info
    "#{datedebut.strftime('%d-%m %H:%M')} - #{full_name}"
  end

  def meeting_details
    "#{nom} - #{datedebut.strftime('%d-%m %H:%M')} - #{full_name}"
  end
  

  def self.ransackable_attributes(auth_object = nil)
    ["client_id", "commande_id", "created_at", "datedebut", "datefin", "id", "id_value", "lieu", "nom", "updated_at"]
  end

  def self.ransackable_associations(auth_object = nil)
    ["client", "commande"]
  end

  private
  
  def add_calendar_event
    google_calendar_service = GoogleCalendarService.new
    event_id = google_calendar_service.create_event_from_meeting(self)
    self.update(google_calendar_event_id: event_id)
  end

  def update_calendar_event
    google_calendar_service = GoogleCalendarService.new
    google_calendar_service.update_event_from_meeting(self)
  end

  def delete_calendar_event
    google_calendar_service = GoogleCalendarService.new
    google_calendar_service.delete_event(self.google_calendar_event_id)
  end
  
end
