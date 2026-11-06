# frozen_string_literal: true

class RubriqueCostume < ApplicationRecord
  has_and_belongs_to_many :produits, join_table: "produits_rubrique_costumes"

  before_validation :normalize_fields

  validates :nom, presence: true, uniqueness: { case_sensitive: false }
  validates :position, numericality: { only_integer: true }

  scope :ordered, -> { order(:position, :nom) }

  # Noms des rubriques seed, sans accents. Une pièce d'époque passe avant un déguisement.
  EPOQUE_MARKERS = %w[renaissance xviiie napoleon belle\ epoque annees marquis marquise medieval moyen\ age epoque].freeze
  DEGUISEMENT_MARKERS = %w[pirate feerie carnaval masque deguisement halloween clown sorcier].freeze
  EPOQUE_NAME = /renaissance|\bxviii|\b18e|\b18eme|napoleon|belle epoque|marquis|marquise|medieval|moyen age|\bepoque\b|annees 19|annees 20|\b19[2-8]0\b/.freeze
  DEGUISEMENT_NAME = /deguisement|carnaval|pirate|\bmasque\b|feerie|halloween|clown|sorcier/.freeze

  # 0 époque, 1 sans signal, 2 déguisement. L'époque gagne si les deux signaux sont présents.
  def self.media_priority(product)
    noms = product.rubrique_costumes.map { |rubrique| fold(rubrique.nom) }
    titre = fold(product.nom)
    return 0 if noms.any? { |nom| marker?(nom, EPOQUE_MARKERS) } || titre.match?(EPOQUE_NAME)
    return 2 if noms.any? { |nom| marker?(nom, DEGUISEMENT_MARKERS) } || titre.match?(DEGUISEMENT_NAME)

    1
  end

  def self.fold(value)
    I18n.transliterate(value.to_s).downcase.strip
  end

  def self.marker?(folded_nom, markers)
    markers.any? { |marker| folded_nom.include?(marker) }
  end

  # Rubriques présentes sur les produits publiés de ce catalogue.
  def self.present_on_catalogue(catalogue)
    ids = Produit.actif.eshop_diffusion
                 .where(catalogue: Produit.catalogue_values_for(catalogue), today_availability: true)
                 .joins(:rubrique_costumes)
                 .distinct
                 .pluck("rubrique_costumes.id")
    where(id: ids).ordered
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[nom position created_at updated_at]
  end

  def hard_destroy_allowed?
    !produits.exists?
  end

  private

  def normalize_fields
    self.nom = nom.to_s.strip
    self.position = 0 if position.blank?
  end
end
