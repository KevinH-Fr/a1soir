class DemandeCabineEssayage < ApplicationRecord
    has_many :demande_cabine_essayage_items, dependent: :destroy
    has_many :produits, through: :demande_cabine_essayage_items
  
    # Enums (gérés en string)
    enum :evenement, {
      mariage: "mariage",
      soiree: "soiree",
      shooting: "shooting",
      autre: "autre"
    }, prefix: true
  
    enum :statut, {
      brouillon: "brouillon",
      soumis: "soumis",
      confirme: "confirme",
      annule: "annule"
    }, suffix: true
  
    accepts_nested_attributes_for :demande_cabine_essayage_items, allow_destroy: true
  
    # Validations
    validates :nom, presence: true
    validates :mail, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
    validates :telephone, presence: true
    #validates :evenement, presence: true
    #validates :date_evenement, presence: true
    validate :has_at_least_one_item

    # Ransackable attributes for admin search
    def self.ransackable_attributes(auth_object = nil)
      ["commentaires", "created_at", "date_evenement", "evenement", "id", "id_value", "mail", "nom", "prenom", "statut", "telephone", "updated_at"]
    end

    def self.ransackable_associations(auth_object = nil)
      ["demande_cabine_essayage_items", "produits"]
    end

    # Helper methods
    def full_name
      [prenom, nom].compact.join(" ")
    end

    def full_name_with_mail
      "#{full_name} (#{mail})"
    end

    private

    def has_at_least_one_item
      if demande_cabine_essayage_items.size == 0
        errors.add(:demande_cabine_essayage_items, "doit contenir au moins un produit")
      end
    end
  end
  