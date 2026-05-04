require 'csv'

class InventaireCsvService
  def initialize(year)
    @year = year.to_i
    @end_of_year = Date.new(@year, 12, 31).end_of_day
  end

  def call

    articles_vendus_map = Article.joins(:commande, :produit)
                                 .merge(Commande.hors_devis)
                                 .vente_only
                                 .where('articles.created_at <= ?', @end_of_year)
                                 .group(:produit_id)
                                 .sum(:quantite)

    sousarticles_vendus_map = Sousarticle.joins(article: [:commande, :produit])
                                         .merge(Commande.hors_devis)
                                         .vente_only
                                         .where('sousarticles.created_at <= ?', @end_of_year)
                                         .group(:produit_id)
                                         .count

    vendus_eshop_map = StripePaymentItem
                         .joins(:stripe_payment)
                         .where(stripe_payments: { status: 'paid' })
                         .where('stripe_payment_items.created_at <= ?', @end_of_year)
                         .group(:produit_id)
                         .count

    CSV.generate(headers: true) do |csv|
      csv << [
        'Nom', 'Prix de vente', 'Prix achat HT', 'Date achat',
        'Fournisseur', 'Stock final (quantité)', 'Stock final (€)'
      ]

      Produit.includes(:categorie_produits, :type_produit, :fournisseur)
             .where('dateachat <= ? OR dateachat IS NULL', @end_of_year)
             .order(:nom).each do |produit|
        quantite_initiale = produit.quantite.to_i
        est_ensemble = produit.type_produit&.nom == 'ensemble'
        est_service = produit.categorie_produits.any? { |cat| cat.service == true }

        vendus_magasin = articles_vendus_map.fetch(produit.id, 0) +
                         sousarticles_vendus_map.fetch(produit.id, 0)
        vendus_eshop   = vendus_eshop_map.fetch(produit.id, 0)

        stock_final = if est_ensemble || est_service
                        1
                      else
                        quantite_initiale - vendus_magasin - vendus_eshop
                      end

        stock_final_euros = (stock_final * produit.prixachat.to_f).round(2)

        csv << [
          produit.nom,
          produit.prixvente,
          produit.prixachat,
          produit.dateachat,
          produit.fournisseur&.nom,
          stock_final,
          stock_final_euros
        ]
      end
    end
  end
end
