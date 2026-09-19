# frozen_string_literal: true

# Tailles à afficher sur les cartes du listing, calculées uniquement
# pour la page courante (après pagination) — pas sur tout le catalogue.
#
# Même clé de regroupement que FiltersProduitsService : [handle, couleur_id].
# Chaque entrée : { nom:, id:, handle: } pour lier vers la fiche de la variante.
#
# Taille « unique » : pas de pastille sur la carte (aucun choix à faire).
class ListingPageTaillesService
  def initialize(produits, taille_filter_id: nil)
    @produits = Array(produits)
    @taille_filter_id = taille_filter_id.presence
  end

  def call
    return {} if @produits.empty?

    # Filtre taille actif : une pastille, celle du filtre (la carte est déjà cette variante).
    return tailles_from_listed_products if @taille_filter_id

    tailles_from_available_siblings
  end

  private

  def key_for(produit)
    [produit.handle, produit.couleur_id]
  end

  def entry_for(produit)
    {
      nom: produit.taille.nom.upcase,
      id: produit.id,
      handle: produit.handle
    }
  end

  # Tille unique en base, mais pas de pastille sur la carte.
  def one_size?(produit)
    produit.taille&.nom.to_s.downcase == "unique"
  end

  def tailles_from_listed_products
    @produits.each_with_object({}) do |produit, hash|
      next if produit.taille&.nom.blank?
      next if one_size?(produit)

      hash[key_for(produit)] = [entry_for(produit)]
    end
  end

  def tailles_from_available_siblings
    pairs = @produits.map { |produit| key_for(produit) }.uniq
    handles = pairs.map(&:first).uniq

    # Une requête pour les SKU dispo des mêmes familles que les cartes de la page.
    # Le where(handle:) est volontairement large ; on restreint ensuite au couple handle+couleur.
    siblings = Produit.actif
                      .eshop_diffusion
                      .where(today_availability: true)
                      .where(handle: handles)
                      .where.not(taille_id: nil)
                      .includes(:taille)
                      .joins(:taille)
                      .order("tailles.nom")

    grouped = pairs.each_with_object({}) { |pair, hash| hash[pair] = [] }

    siblings.each do |produit|
      pair = key_for(produit)
      next unless grouped.key?(pair)
      next if one_size?(produit)

      nom = produit.taille.nom.upcase
      next if grouped[pair].any? { |entry| entry[:nom] == nom }

      grouped[pair] << entry_for(produit)
    end

    grouped
  end
end
