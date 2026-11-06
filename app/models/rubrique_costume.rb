# frozen_string_literal: true

class RubriqueCostume < ApplicationRecord
  has_and_belongs_to_many :produits, join_table: "produits_rubrique_costumes"

  before_validation :normalize_fields

  validates :nom, presence: true, uniqueness: { case_sensitive: false }
  validates :groupe, presence: true
  validates :position, numericality: { only_integer: true }

  scope :ordered, -> { order(:position, :nom) }

  # Rubriques présentes sur les produits publiés de ce catalogue.
  def self.present_on_catalogue(catalogue)
    ids = Produit.actif.eshop_diffusion
                 .where(catalogue: catalogue, today_availability: true)
                 .joins(:rubrique_costumes)
                 .distinct
                 .pluck("rubrique_costumes.id")
    where(id: ids).ordered
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[nom groupe position created_at updated_at]
  end

  def hard_destroy_allowed?
    !produits.exists?
  end

  private

  def normalize_fields
    self.nom = nom.to_s.strip
    self.groupe = groupe.to_s.strip
    self.position = 0 if position.blank?
  end
end
