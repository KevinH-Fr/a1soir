require 'csv'

class InventaireCsvService
  def initialize(year)
    @year = year.to_i
    @end_of_year = Date.new(@year, 12, 31).end_of_day
  end

  def call
    puts "___________ génération inventaire pour l'année #{@year} ___________"

    CSV.generate(headers: true) do |csv|
      csv << [
        'Nom', 'Prix de vente', 'Catégories', 'Date achat',
        'Quantité initiale', 'Vendus magasin', 'Vendus e-shop',
        'Stock final', 'Est un ensemble', 'Est un service'
      ]

      Produit.includes(:categorie_produits, :type_produit).order(:nom).each do |produit|
        nom = produit.nom
        prix = produit.prixvente
        categories = produit.categorie_produits.map(&:nom).join(', ')
        dateachat = produit.dateachat
        quantite_initiale = produit.quantite.to_i

        # Ventes magasin : Articles
        articles_vendus = Article.joins(:commande, :produit)
                                 .merge(Commande.hors_devis)
                                 .vente_only
                                 .where(produit_id: produit.id)
                                 .where('articles.created_at <= ?', @end_of_year)
                                 .sum(:quantite)

        # Ventes magasin : Sousarticles
        sousarticles_vendus = Sousarticle.joins(article: [:commande, :produit])
                                         .merge(Commande.hors_devis)
                                         .vente_only
                                         .where(produit_id: produit.id)
                                         .where('sousarticles.created_at <= ?', @end_of_year)
                                         .count

        vendus_magasin = articles_vendus + sousarticles_vendus

        # Ventes e-shop
        vendus_eshop = StripePaymentItem
                         .joins(:stripe_payment)
                         .where(stripe_payments: { status: 'paid' })
                         .where(produit_id: produit.id)
                         .where('stripe_payment_items.created_at <= ?', @end_of_year)
                         .count

        # Détection ensemble / service
        est_ensemble = produit.type_produit&.nom == 'ensemble'
        est_service = produit.categorie_produits.any? { |cat| cat.service == true }

        # Calcul du stock final
        stock_final = if est_ensemble || est_service
                        1
                      else
                        quantite_initiale - vendus_magasin - vendus_eshop
                      end

        csv << [
          nom, prix, categories, dateachat,
          quantite_initiale, vendus_magasin, vendus_eshop,
          stock_final, est_ensemble, est_service
        ]
      end
    end
  end
end
