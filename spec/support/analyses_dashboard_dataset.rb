# frozen_string_literal: true

# Jeu de données fixe (mars 2026) pour les specs Analyses.
# Réutilisé par db/seeds/99_analyses_demo.rb en développement uniquement — jamais en production.
module AnalysesDashboardDataset
  PERIOD_START = Date.new(2026, 3, 1)
  PERIOD_END = Date.new(2026, 3, 10)

  class << self
    def seed!
      @data = build
      @data
    end

    def data
      @data ||= build
    end

    def build
      # Réserver l'id 1 pour le profil admin technique (exclu des graphiques Analyses).
      Profile.find_or_create_by!(id: Profile::ADMIN_PROFILE_ID) do |p|
        p.prenom = "Admin"
        p.nom = "System"
      end

      client = Client.create!(
        nom: "Analyses",
        prenom: "Client",
        propart: "particulier",
        intitule: Client::INTITULE_OPTIONS.first,
        mail: "analyses-dataset-#{SecureRandom.hex(4)}@test.com"
      )

      profile_a = Profile.create!(prenom: "Vendeur", nom: "Alpha")
      profile_b = Profile.create!(prenom: "Vendeur", nom: "Beta")

      type_robe = TypeProduit.create!(nom: "Robe dataset #{SecureRandom.hex(2)}")
      type_costume = TypeProduit.create!(nom: "Costume dataset #{SecureRandom.hex(2)}")
      fournisseur = Fournisseur.create!(nom: "Fournisseur dataset #{SecureRandom.hex(2)}")

      produit_robe = Produit.create!(
        nom: "Robe test",
        prixvente: 50,
        prixlocation: 100,
        quantite: 5,
        type_produit_id: type_robe.id,
        fournisseur_id: fournisseur.id
      )
      produit_costume = Produit.create!(nom: "Costume test", prixvente: 40, quantite: 5, type_produit_id: type_costume.id)

      t_day1 = Time.zone.local(2026, 3, 2, 10, 0, 0)
      t_in_period = Time.zone.local(2026, 3, 5, 12, 0, 0)
      t_day8 = Time.zone.local(2026, 3, 8, 16, 0, 0)

      commande_boutique_b = Commande.create!(
        client: client,
        profile: profile_b,
        nom: "Boutique B",
        montant: 65,
        devis: false,
        type_locvente: "vente",
        statutarticles: "retiré",
        created_at: t_day1,
        updated_at: t_day1
      )
      Article.create!(
        commande: commande_boutique_b,
        produit: produit_costume,
        quantite: 1,
        prix: 65,
        total: 65,
        locvente: "vente",
        created_at: t_day1,
        updated_at: t_day1
      )
      PaiementRecu.create!(
        commande: commande_boutique_b,
        typepaiement: "prix",
        montant: 65,
        moyen: "chèque",
        created_at: t_day1,
        updated_at: t_day1
      )

      commande_boutique = Commande.create!(
        client: client,
        profile: profile_a,
        nom: "Boutique A",
        montant: 150,
        devis: false,
        type_locvente: "mixte",
        statutarticles: "retiré",
        created_at: t_in_period,
        updated_at: t_in_period
      )
      Article.create!(
        commande: commande_boutique,
        produit: produit_robe,
        quantite: 1,
        prix: 100,
        total: 100,
        locvente: "location",
        created_at: t_in_period,
        updated_at: t_in_period
      )
      Article.create!(
        commande: commande_boutique,
        produit: produit_costume,
        quantite: 1,
        prix: 50,
        total: 50,
        locvente: "vente",
        created_at: t_in_period,
        updated_at: t_in_period
      )
      PaiementRecu.create!(
        commande: commande_boutique,
        typepaiement: "prix",
        montant: 80,
        moyen: "carte bleue",
        created_at: t_in_period,
        updated_at: t_in_period
      )
      PaiementRecu.create!(
        commande: commande_boutique,
        typepaiement: "prix",
        montant: 70,
        moyen: "espèces",
        created_at: t_in_period,
        updated_at: t_in_period
      )

      commande_boutique_same_day = Commande.create!(
        client: client,
        profile: profile_b,
        nom: "Boutique A complément",
        montant: 30,
        devis: false,
        type_locvente: "vente",
        statutarticles: "retiré",
        created_at: t_in_period.change(hour: 17),
        updated_at: t_in_period.change(hour: 17)
      )
      Article.create!(
        commande: commande_boutique_same_day,
        produit: produit_costume,
        quantite: 1,
        prix: 30,
        total: 30,
        locvente: "vente",
        created_at: t_in_period.change(hour: 17),
        updated_at: t_in_period.change(hour: 17)
      )
      PaiementRecu.create!(
        commande: commande_boutique_same_day,
        typepaiement: "prix",
        montant: 30,
        moyen: "carte bleue",
        created_at: t_in_period.change(hour: 17),
        updated_at: t_in_period.change(hour: 17)
      )

      Commande.create!(
        client: client,
        profile: profile_b,
        nom: "Hors période",
        montant: 999,
        devis: false,
        type_locvente: "vente",
        created_at: Time.zone.local(2026, 3, 20, 12, 0, 0),
        updated_at: Time.zone.local(2026, 3, 20, 12, 0, 0)
      )

      Commande.create!(
        client: client,
        profile: profile_a,
        nom: "Devis A",
        montant: 10,
        devis: true,
        type_locvente: "location",
        created_at: Time.zone.local(2026, 3, 4, 10, 0, 0),
        updated_at: Time.zone.local(2026, 3, 4, 10, 0, 0)
      )

      profile_eshop = Profile.for_eshop_commandes

      commande_location_a = Commande.create!(
        client: client,
        profile: profile_a,
        nom: "Location jour 8",
        montant: 40,
        devis: false,
        type_locvente: "location",
        statutarticles: "non-retiré",
        created_at: t_day8,
        updated_at: t_day8
      )
      Article.create!(
        commande: commande_location_a,
        produit: produit_robe,
        quantite: 1,
        prix: 40,
        total: 40,
        locvente: "location",
        created_at: t_day8,
        updated_at: t_day8
      )
      PaiementRecu.create!(
        commande: commande_location_a,
        typepaiement: "prix",
        montant: 40,
        moyen: "virement",
        created_at: t_day8,
        updated_at: t_day8
      )

      commande_eshop = Commande.create!(
        client: client,
        profile: profile_eshop,
        nom: "E-shop C",
        montant: 100,
        devis: false,
        type_locvente: "vente",
        eshop: true,
        created_at: Time.zone.local(2026, 3, 6, 14, 0, 0),
        updated_at: Time.zone.local(2026, 3, 6, 14, 0, 0)
      )
      stripe_payment = StripePayment.create!(
        commande: commande_eshop,
        stripe_payment_id: "pi_dataset_#{SecureRandom.hex(6)}",
        amount: 10_000,
        currency: "eur",
        status: "paid",
        created_at: Time.zone.local(2026, 3, 6, 14, 0, 0),
        updated_at: Time.zone.local(2026, 3, 6, 14, 0, 0)
      )
      StripePaymentItem.create!(
        stripe_payment: stripe_payment,
        produit: produit_robe,
        quantity: 1,
        unit_amount: 6000,
        created_at: Time.zone.local(2026, 3, 6, 14, 0, 0)
      )
      StripePaymentItem.create!(
        stripe_payment: stripe_payment,
        produit: produit_costume,
        quantity: 1,
        unit_amount: 4000,
        created_at: Time.zone.local(2026, 3, 6, 14, 0, 0)
      )
      AvoirRemb.create!(
        commande: commande_eshop,
        type_avoir_remb: "remboursement",
        montant: 20,
        nature: EshopCommandeRemboursementService::NATURE_REMBOURSEMENT,
        custom_date: Date.new(2026, 3, 6)
      )

      {
        profile_a: profile_a,
        profile_b: profile_b,
        type_robe: type_robe,
        type_costume: type_costume,
        fournisseur: fournisseur,
        produit_robe: produit_robe,
        produit_costume: produit_costume
      }
    end

    def period_params
      { debut: PERIOD_START, fin: PERIOD_END }
    end

    # Totaux attendus pour la période fixe (hors profil admin des charts).
    # nb_total_articles = 5 lignes boutique + 2 StripePaymentItems e-shop.
    def expected_baseline
      {
        nb_total_commandes: 5,
        nb_total_articles: 7,
        total_transactions_loc: 140.to_d,
        total_stripe_eur: 80.to_d,
        total_prix_ca: 365.to_d,
        total_prix_ca_cb: 110.to_d,
        total_prix_ca_especes: 70.to_d
      }
    end
  end
end
